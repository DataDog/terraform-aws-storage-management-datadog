# Basic Example

This example demonstrates the minimal configuration for Datadog Storage Management.

## What This Creates

- IAM policy attached to your Datadog integration role
- S3 Inventory configurations on source buckets
- Destination bucket policy for inventory writes
- Datadog Cloud Inventory Sync configuration

## Prerequisites

1. Existing Datadog AWS integration with an IAM role
2. Source S3 buckets to monitor
3. Destination S3 bucket for inventory reports
4. Datadog API and App keys
5. AWS credentials configured

## Usage

```bash
# AWS credentials (one of these methods)
aws configure                           # Interactive setup
# OR
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"

# Datadog credentials
export DD_API_KEY="your-api-key"
export DD_APP_KEY="your-app-key"
# export DD_SITE="datadoghq.com"        # Or datadoghq.eu, etc.

terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description |
|------|-------------|
| `name` | Unique identifier for this configuration |
| `datadog_aws_integration_role_name` | Name of your Datadog integration IAM role |
| `source_bucket_names` | List of buckets to enable inventory on |
| `destination_bucket_name` | Bucket to store inventory reports |

