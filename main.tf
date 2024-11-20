locals {
  aws_account_id    = data.aws_caller_identity.current.account_id
  oidc_issuer       = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn = replace(local.oidc_issuer, "https://", "arn:aws:iam::${local.aws_account_id}:oidc-provider/")
  oidc_endpoint     = replace(local.oidc_issuer, "https://", "")
}

resource "aws_iam_role" "this" {
  name = "${var.irsa_role_name}-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = "${local.oidc_provider_arn}"
        },
        Condition = {
          StringEquals = {
            "${local.oidc_endpoint}:aud" = "sts.amazonaws.com",
            "${local.oidc_endpoint}:sub" = "system:serviceaccount:${var.service_account.namespace}:${var.service_account.name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  for_each = { for idx, policy in var.policies : idx => policy }

  name = each.value.name

  policy = jsonencode({
    Version = each.value.version
    Statement = [
      for statement in each.value.statements : {
        Sid      = statement.sid != null ? statement.sid : null
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
        Condition = statement.condition != null ? {
          StringEquals = statement.condition.string_equals != null ? statement.condition.string_equals : null,
          StringLike   = statement.condition.string_like != null ? statement.condition.string_like : null
        } : null
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "predefined_policies" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "dynamic_policies" {
  count      = length(aws_iam_policy.this)
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[count.index].arn
}
