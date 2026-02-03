output "destination_bucket_policy_json" {
  description = <<-EOT
    Complete bucket policy JSON for S3 Inventory writes. 
    Apply directly if bucket has no policy: terraform output -raw destination_bucket_policy_json | aws s3api put-bucket-policy --bucket BUCKET --policy file:///dev/stdin
    To extract just the statement for manual merging: jsondecode(module.this.destination_bucket_policy_json).Statement[0]
  EOT
  value = jsonencode({
    Version   = "2012-10-17"
    Statement = [local.inventory_write_statement]
  })
}
