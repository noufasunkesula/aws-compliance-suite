# Phase 7 – Centralized Logging with CloudTrail & CloudWatch

# 7.1 – Enable Multi-Region CloudTrail into your S3 Bucket
# Replace <YOUR_BUCKET_NAME> with your Config bucket
$bucket = "<YOUR_BUCKET_NAME>"

# Grant CloudTrail permission to write into the bucket
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": ["s3:GetBucketAcl", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::$bucket",
        "arn:aws:s3:::$bucket/AWSLogs/<YOUR_ACCOUNT_ID>/*"
      ]
    }
  ]
}
"@ | Out-File .\ct-bucket-policy.json -Encoding ascii

aws s3api put-bucket-policy --bucket $bucket --policy file://./ct-bucket-policy.json

# Create and start the CloudTrail trail
aws cloudtrail create-trail `
  --name SecuritySuiteTrail `
  --s3-bucket-name $bucket `
  --is-multi-region-trail

aws cloudtrail start-logging --name SecuritySuiteTrail

# 7.2 – Send Trail Events to CloudWatch Logs

# Create a CloudWatch Logs group
aws logs create-log-group --log-group-name SecuritySuiteTrail-Logs

# Create trust policy for CloudTrail → CloudWatch
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File .\ct-cw-trust.json -Encoding ascii

# Create IAM role with CloudWatch permissions
aws iam create-role `
  --role-name CT-CloudWatch-Role `
  --assume-role-policy-document file://./ct-cw-trust.json

aws iam attach-role-policy `
  --role-name CT-CloudWatch-Role `
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

# Link CloudTrail to CloudWatch Logs
$acct = aws sts get-caller-identity --query Account --output text
$reg  = aws configure get region
$logArn  = "arn:aws:logs:$reg:$acct:log-group:SecuritySuiteTrail-Logs"
$roleArn = "arn:aws:iam::$acct:role/CT-CloudWatch-Role"

aws cloudtrail update-trail `
  --name SecuritySuiteTrail `
  --cloud-watch-logs-log-group-arn $logArn `
  --cloud-watch-logs-role-arn $roleArn

# 7.3 – Metric Filter & Alarm for S3 Bucket Policy Changes

# Create a metric filter on policy changes
aws logs put-metric-filter `
  --log-group-name SecuritySuiteTrail-Logs `
  --filter-name S3PolicyChangeFilter `
  --filter-pattern '{ ($.eventName = PutBucketPolicy) || ($.eventName = DeleteBucketPolicy) }' `
  --metric-transformations metricName=S3PolicyChanges,metricNamespace=SecuritySuite,metricValue=1

# Create an SNS topic for notifications
$topicArn = aws sns create-topic `
  --name SecurityAlerts `
  --query TopicArn `
  --output text

# Create CloudWatch alarm on S3 policy changes
aws cloudwatch put-metric-alarm `
  --alarm-name S3PolicyChangeAlarm `
  --metric-name S3PolicyChanges `
  --namespace SecuritySuite `
  --statistic Sum `
  --period 300 `
  --threshold 1 `
  --comparison-operator GreaterThanOrEqualToThreshold `
  --evaluation-periods 1 `
  --alarm-actions $topicArn

# Verification
aws cloudtrail describe-trails --query "trailList[?Name=='SecuritySuiteTrail']"
aws cloudwatch describe-alarms --alarm-names S3PolicyChangeAlarm
