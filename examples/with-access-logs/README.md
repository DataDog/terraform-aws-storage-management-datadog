# Example with Access Logging

This example demonstrates Storage Management with S3 access logging enabled for prefix-level metrics.

## What This Creates

Everything from the basic example, plus:

- S3 access logging configuration on source buckets
- Lambda permission for S3 to invoke the Datadog Forwarder
- S3 bucket notification to trigger the Forwarder on new access logs

## Prerequisites

1. Everything from the basic example
2. An S3 bucket for access logs (with appropriate ACLs)
3. Datadog API key stored in AWS Secrets Manager
4. AWS credentials configured

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

## Access Log Bucket Setup

The access log bucket must have the proper ACL to receive logs:

```hcl
resource "aws_s3_bucket" "access_logs" {
  bucket = "my-access-logs-bucket"
}

resource "aws_s3_bucket_acl" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  acl    = "log-delivery-write"
}
```

## Merging with Existing Notifications

If your access log bucket already has S3 notifications configured, pass them in to avoid overwriting:

```hcl
module "datadog_storage_management" {
  source = "../../"
  # ... other variables ...

  access_log_bucket_notifications = {
    lambda_functions = [
      {
        lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-existing-function"
        events              = ["s3:ObjectCreated:*"]
        filter_prefix       = "other-logs/"
      }
    ]
  }
}
```
