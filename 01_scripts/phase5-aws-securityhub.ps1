# Enable AWS Security Hub in the current region
aws securityhub enable-security-hub

# Describe the current Security Hub configuration
aws securityhub describe-hub

# Write the standards subscription JSON to file
@"
{
  "StandardsSubscriptionRequests": [
    {
      "StandardsArn": "arn:aws:securityhub:<YourRegion>::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
  ]
}
"@ | Out-File .\enable-foundational.json -Encoding ascii

# Enable the foundational security best practices standard
aws securityhub batch-enable-standards `
  --cli-input-json file://./enable-foundational.json

# Verify which standards are enabled
aws securityhub get-enabled-standards
