# Datadog Storage Management for AWS

Terraform module to configure [Datadog Storage Management](https://docs.datadoghq.com/storage_management/) for AWS S3.

## Features

- Configures S3 Inventory on source buckets
- Grants required IAM permissions to your Datadog integration role
- Creates Datadog Cloud Inventory Sync configuration
- Optionally manages destination bucket policy (safe default: off)
- Optionally enables S3 access logging for prefix-level metrics

## Prerequisites

1. **Datadog AWS Integration**: An existing [Datadog AWS integration](https://docs.datadoghq.com/integrations/amazon_web_services/) with an IAM role
2. **S3 Buckets**: Existing source buckets to monitor and a destination bucket for inventory reports
3. **Datadog Credentials**: API and App keys for the Datadog provider

## Provider Configuration

```hcl
provider "datadog" {
  # Set via environment variables:
  #   export DD_API_KEY="your-api-key"
  #   export DD_APP_KEY="your-app-key"
}

provider "aws" {
  region = "us-east-1"

  # AWS credentials can be configured via:
  # - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # - Shared credentials file (~/.aws/credentials)
  # - IAM instance profile (when running on EC2/ECS)
  # See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
}
```

## Usage

### Basic Usage (New Destination Bucket)

If your destination bucket has **no existing policy**, let the module manage it:

```hcl
module "datadog_storage_management" {
  source  = "DataDog/storage-management-datadog/aws"
  version = "~> 1.0"

  name                              = "main"
  datadog_aws_integration_role_name = "DatadogIntegrationRole"
  source_bucket_names               = ["my-app-data", "my-logs-bucket"]
  destination_bucket_name           = "my-inventory-destination"

  # Let module create the bucket policy (safe for new/empty buckets)
  manage_destination_bucket_policy = true
}
```

### Basic Usage (Apply Policy Yourself)

If you prefer to manage the bucket policy externally (default, safest):

```hcl
module "datadog_storage_management" {
  source  = "DataDog/storage-management-datadog/aws"
  version = "~> 1.0"

  name                              = "main"
  datadog_aws_integration_role_name = "DatadogIntegrationRole"
  source_bucket_names               = ["my-app-data", "my-logs-bucket"]
  destination_bucket_name           = "my-inventory-destination"
  # manage_destination_bucket_policy = false (default)
}

# IMPORTANT: Apply the bucket policy from the output
# terraform output -json destination_bucket_policy_json
```

### With Access Logging (Prefix-Level Metrics)

```hcl
# Deploy the Datadog Forwarder (one per region/account)
module "datadog_forwarder" {
  source  = "DataDog/log-lambda-forwarder-datadog/aws"
  version = "~> 1.2"

  function_name         = "datadog-forwarder"
  dd_api_key_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:datadog-api-key"
  dd_site               = "datadoghq.com"
}

# Configure Storage Management with access logging
module "datadog_storage_management" {
  source  = "DataDog/storage-management-datadog/aws"
  version = "~> 1.0"

  name                              = "main"
  datadog_aws_integration_role_name = "DatadogIntegrationRole"
  source_bucket_names               = ["my-app-data", "my-logs-bucket"]
  destination_bucket_name           = "my-inventory-destination"

  # Enable access logging for prefix-level metrics
  enable_access_logging  = true
  access_log_bucket_name = "my-access-logs-bucket"
  datadog_forwarder_arn  = module.datadog_forwarder.datadog_forwarder_arn
}
```

### Managing Bucket Policies

**Option 1: Apply policy yourself (default, safest):**
```hcl
module "datadog_storage_management" {
  # ... other variables ...
  # destination_bucket_policy_management = "none" (default)
}

# Then run: terraform output -raw destination_bucket_policy_json | aws s3api put-bucket-policy --bucket BUCKET --policy file:///dev/stdin
```

**Option 2: New bucket (no existing policy):**
```hcl
module "datadog_storage_management" {
  # ... other variables ...
  destination_bucket_policy_management = "create"
}
```

**Option 3: Existing bucket with policy (merge):**
```hcl
module "datadog_storage_management" {
  # ... other variables ...
  destination_bucket_policy_management = "merge"  # Reads existing, adds our statement
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| datadog | >= 3.50 |

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Unique name for this configuration (used in resource names) | `string` | n/a | yes |
| `datadog_aws_integration_role_name` | Name of the Datadog AWS integration IAM role | `string` | n/a | yes |
| `source_bucket_names` | List of S3 bucket names to enable inventory on | `list(string)` | n/a | yes |
| `destination_bucket_name` | S3 bucket name for inventory reports | `string` | n/a | yes |
| `destination_prefix` | Prefix path within the destination bucket | `string` | `"datadog-inventories/"` | no |
| `destination_bucket_policy_management` | How to handle bucket policy: "none", "create", or "merge" | `string` | `"none"` | no |
| `enable_access_logging` | Enable S3 access logging for prefix-level metrics | `bool` | `false` | no |
| `access_log_bucket_name` | S3 bucket for access logs | `string` | `""` | no |
| `access_log_prefix` | Prefix for access log objects | `string` | `"s3-access-logs/"` | no |
| `datadog_forwarder_arn` | ARN of existing Datadog Forwarder Lambda | `string` | `""` | no |
| `access_log_bucket_notifications` | Existing notifications to merge | `object` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `destination_bucket_policy_json` | Complete bucket policy JSON for S3 Inventory writes |

## Resources Created

| Resource | Description | Created when |
|----------|-------------|--------------|
| `aws_iam_role_policy` | Inline policy on Datadog role | Always |
| `aws_s3_bucket_policy` | Destination bucket policy | `manage_destination_bucket_policy = true` |
| `aws_s3_bucket_inventory` | Inventory config per source bucket | Always |
| `datadog_cloud_inventory_sync_config` | Datadog sync configuration | Always |
| `aws_s3_bucket_logging` | Access logging on source buckets | `enable_access_logging = true` |
| `aws_lambda_permission` | S3 → Lambda invoke permission | `enable_access_logging = true` |
| `aws_s3_bucket_notification` | Access log bucket notifications | `enable_access_logging = true` |

## Limitations

- **Single Account Only**: Source and destination buckets must be in the same AWS account
- **Same Region**: All buckets must be in the same AWS region
- **Access Logging Overwrites**: Enabling access logging will overwrite existing logging configuration on source buckets

## IAM Permissions

The module attaches an inline policy to your Datadog integration role with these permissions:

```json
{
  "Statement": [
    {
      "Sid": "DatadogS3BucketInfo",
      "Effect": "Allow",
      "Action": [
        "s3:GetAccelerateConfiguration",
        "s3:GetAnalyticsConfiguration",
        "s3:GetBucket*",
        "s3:GetEncryptionConfiguration",
        "s3:GetInventoryConfiguration",
        "s3:GetLifecycleConfiguration",
        "s3:GetMetricsConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:ListAllMyBuckets",
        "s3:ListBucket"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DatadogReadInventoryReports",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::DESTINATION_BUCKET/*"]
    }
  ]
}
```

> **Note**: Inventory configurations are managed by Terraform, not Datadog. This ensures no state drift between Terraform and Datadog's API.

## License

See [LICENSE](LICENSE) for details.
