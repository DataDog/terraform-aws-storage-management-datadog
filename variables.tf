################################################################################
# Required Variables
################################################################################

variable "name" {
  description = "Unique name for this Storage Management configuration. Used in resource names to prevent collisions when deploying multiple instances."
  type        = string
}

variable "datadog_aws_integration_role_name" {
  description = "Name of the existing Datadog AWS integration IAM role to attach permissions to."
  type        = string
}

variable "source_bucket_names" {
  description = "List of S3 bucket names to enable inventory on."
  type        = list(string)
}

variable "destination_bucket_name" {
  description = "Name of the S3 bucket where inventory reports will be stored."
  type        = string
}

################################################################################
# Optional Variables
################################################################################

variable "destination_prefix" {
  description = "Prefix path within the destination bucket for inventory files."
  type        = string
  default     = "datadog-inventories/"
}

variable "destination_bucket_policy_management" {
  description = <<-EOT
    How to handle the destination bucket policy:
    - "none" (default): Don't manage. Apply policy yourself: terraform output -raw destination_bucket_policy_json | aws s3api put-bucket-policy --bucket BUCKET --policy file:///dev/stdin
    - "create": Create a fresh policy with only the required inventory statement.
    - "merge": Read existing policy and add the required inventory statement.
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "create", "merge"], var.destination_bucket_policy_management)
    error_message = "Must be 'none', 'create', or 'merge'."
  }
}

################################################################################
# Access Logging Variables (Optional)
################################################################################

variable "enable_access_logging" {
  description = "Enable S3 access logging on source buckets for prefix-level metrics."
  type        = bool
  default     = false
}

variable "access_log_bucket_name" {
  description = "Name of the S3 bucket to store access logs. Required if enable_access_logging is true."
  type        = string
  default     = ""
}

variable "access_log_prefix" {
  description = "Prefix for access log objects in the access log bucket."
  type        = string
  default     = "s3-access-logs/"
}

variable "datadog_forwarder_arn" {
  description = "ARN of an existing Datadog Forwarder Lambda function. Required if enable_access_logging is true."
  type        = string
  default     = ""
}

variable "access_log_bucket_notifications" {
  description = "Existing S3 bucket notification lambda functions to merge with the Datadog Forwarder notification. Structure: { lambda_functions = [{ lambda_function_arn, events, filter_prefix }] }"
  type = object({
    lambda_functions = optional(list(object({
      lambda_function_arn = string
      events              = list(string)
      filter_prefix       = optional(string, "")
      filter_suffix       = optional(string, "")
    })), [])
  })
  default = {}
}

