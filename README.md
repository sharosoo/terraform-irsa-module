# Terraform IRSA Module

This Terraform module allows you to easily create an **IAM Role for Service Accounts (IRSA)** in an AWS environment. It eliminates repetitive resource definitions by providing a reusable and configurable module.

## Features

- Simplifies the creation of IRSA roles.
- Attaches AWS managed policies and custom inline policies to the role.
- Associates the role with a specific Kubernetes service account.
- Supports dynamic policy definitions to fine-tune permissions.

## Usage

Here's an example of how to use this module in your Terraform configuration:

### Example Configuration

```hcl
provider "aws" {
  alias  = "cluster_region"
  region = "<your-cluster-region>"
}

module "example_irsa" {
  source  = "sharosoo/module/irsa"
  version = "0.0.3"

  cluster_name   = "<your-cluster-name>"
  policy_arns    = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  ]
  irsa_role_name = "ExampleIRSAUpdateRole"
  service_account = {
    name      = "example-service-account"
    namespace = "default"
  }
  policies = [
    {
      name    = "CustomPolicyExample"
      version = "2012-10-17"
      statements = [
        {
          sid      = "AllowSpecificAction"
          effect   = "Allow"
          actions  = ["ec2:DescribeInstances"]
          resource = "*"
        },
        {
          sid    = "DenySpecificAction"
          effect = "Deny"
          actions = ["ec2:TerminateInstances"]
          resource = "*"
        }
      ]
    }
  ]
  providers = {
    aws = aws.cluster_region
  }
}
```

## Inputs

| Name              | Description                                                                                 | Type     | Default | Required |
|-------------------|---------------------------------------------------------------------------------------------|----------|---------|----------|
| `cluster_name`    | The name of the Kubernetes cluster where the IRSA role will be used.                        | `string` | N/A     | Yes      |
| `policy_arns`     | A list of AWS managed policies to attach to the role.                                       | `list`   | `[]`    | Yes      |
| `irsa_role_name`  | The name of the IAM role to be created.                                                     | `string` | N/A     | Yes      |
| `service_account` | A map containing `name` and `namespace` for the Kubernetes service account to associate.    | `map`    | N/A     | Yes      |
| `policies`        | A list of custom inline policies to attach to the IAM role, with statements for permissions.| `list`   | `[]`    | No       |
| `providers`       | AWS providers, allowing region aliasing for flexibility.                                    | `map`    | N/A     | Yes      |

## Outputs

| Name               | Description                                                     |
|--------------------|-----------------------------------------------------------------|
| `iam_role_arn`     | The Amazon Resource Name (ARN) of the created IAM role.         |
| `service_account`  | The name and namespace of the associated Kubernetes service account. |

## Example Walkthrough

### 1. Provider Setup

Define the AWS provider with the desired region.

```hcl
provider "aws" {
  alias  = "cluster_region"
  region = "us-east-1"
}
```

### 2. IRSA Role Creation

Use the module to create an IRSA role. Customize:

- The cluster name.
- Service account details.
- Policies (managed and custom inline).

### 3. Deploy to Kubernetes

After applying the Terraform configuration, associate the created IAM role with the specified Kubernetes service account. This allows the service account to inherit AWS permissions.

## Benefits of Using This Module

- Reusability: Define once and reuse across multiple projects.
- Customization: Add fine-grained permissions with custom inline policies.
- Automation: Automate role creation and reduce manual steps in configuring IRSA.

## Contributions

Contributions are welcome! Please submit a pull request or open an issue for feedback or feature requests.
