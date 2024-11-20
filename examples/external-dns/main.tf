provider "aws" {
  alias  = "cluster_region"
  region = "ap-northeast-1"
}

module "external_dns_irsa" {
  source  = "sharosoo/module/irsa"
  version = "0.0.4"

  cluster_name = "turing-cluster"
  policy_arns = [
    # "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  ]
  irsa_role_name = "ExtranlDNSUpdateRole"
  service_account = {
    name      = "external-dns"
    namespace = "kube-system"
  }
  policies = [
    {
      name    = "AllowExternalDNSUpdatesPolicy-my-cluster"
      version = "2012-10-17"
      statements = [
        {
          sid       = "AllowRoute53Changes"
          effect    = "Allow"
          actions   = ["route53:ChangeResourceRecordSets"]
          resources = ["arn:aws:route53:::hostedzone/*"]
        },
        {
          sid    = "AllowRoute53ReadAccess"
          effect = "Allow"
          actions = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
            "route53:ListTagsForResource"
          ]
          resources = ["*"]
        }
      ]
    }
  ]
  providers = {
    aws = aws.cluster_region
  }
}
