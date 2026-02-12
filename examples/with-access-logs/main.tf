# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2026 Datadog, Inc.

# Example with access logging enabled for prefix-level metrics

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

# Deploy the Datadog Forwarder (one per region/account)
# See: https://github.com/DataDog/terraform-aws-log-lambda-forwarder-datadog
module "datadog_forwarder" {
  source  = "DataDog/log-lambda-forwarder-datadog/aws"
  version = "~> 1.2"

  function_name         = "datadog-forwarder"
  dd_api_key_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:datadog-api-key"
  dd_site               = "datadoghq.com"
}

# Configure Storage Management with access logging
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

  # Enable access logging for prefix-level metrics
  enable_access_logging  = true
  access_log_bucket_name = "my-access-logs-bucket"
  datadog_forwarder_arn  = module.datadog_forwarder.datadog_forwarder_arn
}
