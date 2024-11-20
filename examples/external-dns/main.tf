provider "aws" {
  alias  = "cluster_region"
  region = "<your-cluster-region>"
}

module "external_dns_irsa" {
  source  = "sharosoo/module/irsa"
  version = "0.0.3"

  cluster_name = "<your-cluster-name>"
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
          sid      = "AllowRoute53Changes"
          effect   = "Allow"
          actions  = ["route53:ChangeResourceRecordSets"]
          resource = "arn:aws:route53:::hostedzone/*"
        },
        {
          sid    = "AllowRoute53ReadAccess"
          effect = "Allow"
          actions = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
            "route53:ListTagsForResource"
          ]
          resource = "*"
        }
      ]
    }
  ]
  providers = {
    aws = aws.cluster_region
  }
}
