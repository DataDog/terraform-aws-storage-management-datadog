# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2026 Datadog, Inc.

################################################################################
# Input Validation
################################################################################

check "access_logging_requirements" {
  assert {
    condition     = !var.enable_access_logging || var.access_log_bucket_name != ""
    error_message = "access_log_bucket_name is required when enable_access_logging is true."
  }
  assert {
    condition     = !var.enable_access_logging || var.datadog_forwarder_arn != ""
    error_message = "datadog_forwarder_arn is required when enable_access_logging is true."
  }
}

################################################################################
# IAM Policy for Datadog Storage Management
################################################################################

data "aws_iam_policy_document" "storage_management" {
  # General S3 bucket info permissions (all buckets)
  statement {
    sid    = "DatadogS3BucketInfo"
    effect = "Allow"

    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucket*", # Covers GetBucketLocation, GetBucketLogging, GetBucketTagging, etc.
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
    ]

    resources = ["*"]
  }

  # Read inventory reports from destination bucket (scoped to prefix)
  statement {
    sid    = "DatadogReadInventoryFromDestinationBucket"
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.destination_bucket_name}/${var.destination_prefix}*"
    ]
  }
}

resource "aws_iam_role_policy" "storage_management" {
  name   = "DatadogStorageManagement-${var.name}"
  role   = var.datadog_aws_integration_role_name
  policy = data.aws_iam_policy_document.storage_management.json
}

################################################################################
# Destination Bucket Policy
################################################################################

# Read existing bucket policy (only in merge mode)
data "aws_s3_bucket_policy" "destination" {
  count  = var.destination_bucket_policy_management == "merge" ? 1 : 0
  bucket = var.destination_bucket_name
}

locals {
  # The policy statement required for S3 Inventory to write reports
  inventory_write_statement = {
    Sid       = "S3InventoryWrite-${var.name}"
    Effect    = "Allow"
    Principal = { Service = "s3.amazonaws.com" }
    Action    = "s3:PutObject"
    Resource  = "arn:aws:s3:::${var.destination_bucket_name}/${var.destination_prefix}*"
    Condition = {
      StringEquals = {
        "aws:SourceAccount" = data.aws_caller_identity.current.account_id
      }
      ArnLike = {
        "aws:SourceArn" = [for bucket in var.source_bucket_names : "arn:aws:s3:::${bucket}"]
      }
    }
  }

  # Combine existing statements (if merge mode) with our required statement
  all_policy_statements = concat(
    var.destination_bucket_policy_management == "merge" ? jsondecode(data.aws_s3_bucket_policy.destination[0].policy).Statement : [],
    [local.inventory_write_statement]
  )
}

resource "aws_s3_bucket_policy" "destination" {
  count = var.destination_bucket_policy_management != "none" ? 1 : 0

  bucket = var.destination_bucket_name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.all_policy_statements
  })
}

################################################################################
# S3 Inventory Configuration
################################################################################

resource "aws_s3_bucket_inventory" "source" {
  for_each = toset(var.source_bucket_names)

  bucket = each.value
  name   = "DatadogStorageManagement-${var.name}"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      bucket_arn = "arn:aws:s3:::${var.destination_bucket_name}"
      format     = "CSV"
      prefix     = var.destination_prefix
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier",
    "BucketKeyStatus",
    "ChecksumAlgorithm",
  ]
}

# NOTE: If destination_bucket_policy_management = "none", inventory reports won't be 
# delivered until you apply the policy from the output.

################################################################################
# Datadog Cloud Inventory Sync Configuration
################################################################################

resource "datadog_cloud_inventory_sync_config" "inventory_sync" {
  cloud_provider = "aws"

  aws {
    aws_account_id            = data.aws_caller_identity.current.account_id
    destination_bucket_name   = var.destination_bucket_name
    destination_bucket_region = data.aws_region.current.id
    destination_prefix        = var.destination_prefix
  }
}

################################################################################
# S3 Access Logging (Optional)
################################################################################

resource "aws_s3_bucket_logging" "source" {
  for_each = var.enable_access_logging ? toset(var.source_bucket_names) : toset([])

  bucket = each.value

  target_bucket = var.access_log_bucket_name
  target_prefix = "${var.access_log_prefix}${each.value}/"
}

# Grant S3 permission to invoke the Datadog Forwarder Lambda
resource "aws_lambda_permission" "s3_invoke_forwarder" {
  count = var.enable_access_logging ? 1 : 0

  statement_id   = "AllowS3InvokeStorageManagement-${var.name}"
  action         = "lambda:InvokeFunction"
  function_name  = var.datadog_forwarder_arn
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::${var.access_log_bucket_name}"
  source_account = data.aws_caller_identity.current.account_id
}

# S3 bucket notification to trigger Datadog Forwarder
locals {
  forwarder_notification = var.enable_access_logging ? {
    lambda_function_arn = var.datadog_forwarder_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.access_log_prefix
    filter_suffix       = ""
  } : null

  all_lambda_notifications = var.enable_access_logging ? concat(
    var.access_log_bucket_notifications.lambda_functions,
    [local.forwarder_notification]
  ) : []
}

resource "aws_s3_bucket_notification" "access_logs" {
  count = var.enable_access_logging ? 1 : 0

  bucket = var.access_log_bucket_name

  dynamic "lambda_function" {
    for_each = local.all_lambda_notifications
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  depends_on = [aws_lambda_permission.s3_invoke_forwarder]
}
