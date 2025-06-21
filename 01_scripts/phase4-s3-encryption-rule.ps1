# Write the AWS Config managed rule definition to a JSON file
@"
{
  "ConfigRuleName": "s3-bucket-encryption-check",
  "Description": "Ensure S3 buckets have SSE enabled",
  "Scope": {
    "ComplianceResourceTypes": ["AWS::S3::Bucket"]
  },
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
"@ | Out-File .\s3-encryption-rule.json -Encoding ascii

# Create the AWS Config rule from the JSON file
aws configservice put-config-rule `
  --config-rule file://./s3-encryption-rule.json

# Describe the newly created rule
aws configservice describe-config-rules `
  --config-rule-names s3-bucket-encryption-check

# Check compliance status for resources evaluated by the rule
aws configservice get-compliance-details-by-config-rule `
  --config-rule-name s3-bucket-encryption-check `
  --compliance-types COMPLIANT NON_COMPLIANT
