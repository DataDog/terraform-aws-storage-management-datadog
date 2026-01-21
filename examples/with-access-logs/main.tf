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

  # Bucket policy: "none" (default), "create", or "merge"
  destination_bucket_policy_management = "create"

  # Enable access logging for prefix-level metrics
  enable_access_logging  = true
  access_log_bucket_name = "my-access-logs-bucket"
  datadog_forwarder_arn  = module.datadog_forwarder.datadog_forwarder_arn
}
