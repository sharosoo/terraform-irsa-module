variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "irsa_role_name" {
  description = "The name of the IRSA role"
  type        = string
}

variable "service_account" {
  type = object({
    name      = string
    namespace = string
  })
  description = "The service account to attach the IRSA role to"
}

variable "policies" {
  type = list(
    object(
      {
        name    = string
        version = optional(string, "2012-10-17")
        statements = list(
          object(
            {
              sid = optional(string, "")
              condition = optional(
                object(
                  {
                    string_equals = optional(
                      map(string)
                    )
                    string_like = optional(
                      map(string)
                    )
                  }
                )
              )
              effect    = string
              actions   = list(string)
              resources = list(string)
            }
          )
        )
      }
    )
  )
  description = "The policies to be created and attached to the IRSA role"
  default     = []
}

variable "policy_arns" {
  type        = list(string)
  description = "The policy arns attached to the IRSA role"
  default     = []
}
