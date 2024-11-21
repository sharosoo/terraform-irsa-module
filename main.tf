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
    Version = each.value.version,
    Statement = [
      for statement in each.value.statements : merge(
        statement.not_actions != null ? { NotAction : statement.not_actions } : {},
        statement.resources != null ? { Resource : statement.resources } : {},
        statement.not_resources != null ? { NotResource : statement.not_resources } : {},
        statement.principals != null ? { Principal : statement.principals } : {},
        statement.effect != null ? { Effect : statement.effect } : {},
        statement.actions != null ? { Action : statement.actions } : {},
        statement.not_principals != null ? { NotPrincipal : statement.not_principals } : {},
        statement.sid != null ? { Sid = statement.sid } : {},
        statement.condition != null ? { Condition = statement.condition } : {}
      )
    ]
  })
}

resource "aws_iam_role_policy_attachment" "predefined_policies" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "dynamic_policies" {
  for_each = aws_iam_policy.this

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}
