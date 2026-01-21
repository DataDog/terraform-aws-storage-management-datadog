data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_role" "datadog_integration" {
  name = var.datadog_aws_integration_role_name
}

