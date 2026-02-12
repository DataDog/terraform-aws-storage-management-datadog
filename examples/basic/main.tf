# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2026 Datadog, Inc.

# Basic example - S3 Inventory and Cloud Inventory Sync only
# No access logging for prefix-level metrics

provider "aws" {
  region = "us-east-1"
  # Configure via: aws configure
  # Or environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
}

provider "datadog" {
  # Configure via environment variables:
  #   export DD_API_KEY="your-api-key"
  #   export DD_APP_KEY="your-app-key"
  #   export DD_SITE="datadoghq.com"  # or datadoghq.eu, etc.
}

module "datadog_storage_management" {
  source = "../../"

  name                              = "main"
  datadog_aws_integration_role_name = "DatadogIntegrationRole"
  source_bucket_names               = ["my-app-data", "my-logs-bucket"]
  destination_bucket_name           = "my-inventory-destination"

  # Bucket policy: "merge" (default), "create" (for new buckets), or "none"
  # Using "create" here as example shows a new bucket without existing policy
  destination_bucket_policy_management = "create"

  # Auto-expire inventory reports after 2 days to prevent bucket growth
  # WARNING: Only enable on dedicated buckets - this overwrites ALL existing lifecycle rules
  manage_destination_lifecycle = true
}
