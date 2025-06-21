# Phase 9 – Compliance Dashboard & Reporting

# 9.1 – Define the dashboard JSON
@"
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Config", "ComplianceEvaluations", "ConfigRuleName", "s3-bucket-encryption-check" ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "<YOUR_REGION>",
        "title": "S3 Encryption Compliance"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 7,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "SecuritySuite", "S3PolicyChanges" ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "<YOUR_REGION>",
        "title": "S3 Policy Change Events"
      }
    }
  ]
}
"@ | Out-File .\dashboard.json -Encoding ascii

# 9.2 – Create or update the CloudWatch dashboard
aws cloudwatch put-dashboard `
  --dashboard-name ComplianceDashboard `
  --dashboard-body file://./dashboard.json

# 9.3 – Verify the dashboard exists
aws cloudwatch get-dashboard --dashboard-name ComplianceDashboard
