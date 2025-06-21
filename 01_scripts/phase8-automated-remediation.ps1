# Phase 8 – Automated Remediation for S3 Bucket Encryption

# 8.1 – Create the IAM Role for the Remediation Lambda
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File .\lambda-trust.json -Encoding ascii

aws iam create-role `
  --role-name RemediationLambdaRole `
  --assume-role-policy-document file://./lambda-trust.json

# Attach AWS-managed basic Lambda execution role
aws iam attach-role-policy `
  --role-name RemediationLambdaRole `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Grant S3 encryption permissions
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutBucketEncryption",
        "s3:GetBucketEncryption"
      ],
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
"@ | Out-File .\s3-encrypt-policy.json -Encoding ascii

aws iam put-role-policy `
  --role-name RemediationLambdaRole `
  --policy-name S3EncryptPolicy `
  --policy-document file://./s3-encrypt-policy.json

# 8.2 – Write & Package the Lambda Function
@"
import json
import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    invoking = json.loads(event['invokingEvent'])
    bucket = invoking['configurationItem']['resourceName']
    s3.put_bucket_encryption(
        Bucket=bucket,
        ServerSideEncryptionConfiguration={
            'Rules': [{
                'ApplyServerSideEncryptionByDefault': {
                    'SSEAlgorithm': 'AES256'
                }
            }]
        }
    )
    print(f"Encrypted: {bucket}")
    return {"statusCode": 200}
"@ | Out-File .\encrypt_s3.py -Encoding ascii

Compress-Archive -Path encrypt_s3.py -DestinationPath encrypt_s3.zip

# 8.3 – Deploy the Lambda Function
# Replace <ACCOUNT_ID> with your AWS account number
$roleArn = "arn:aws:iam::<ACCOUNT_ID>:role/RemediationLambdaRole"

aws lambda create-function `
  --function-name EncryptUnencryptedBuckets `
  --runtime python3.9 `
  --handler encrypt_s3.lambda_handler `
  --zip-file fileb://encrypt_s3.zip `
  --role $roleArn

# 8.4 – Attach AWS-Managed Remediation to Config Rule
@"
[
  {
    "ConfigRuleName": "s3-bucket-encryption-check",
    "TargetType": "SSM_DOCUMENT",
    "TargetId": "AWS-EnableS3BucketEncryption",
    "Automatic": true,
    "Parameters": {}
  }
]
"@ | Out-File .\remediation.json -Encoding ascii

aws configservice put-remediation-configurations `
  --remediation-configurations file://./remediation.json

# Verification
aws lambda get-function --function-name EncryptUnencryptedBuckets
aws configservice describe-remediation-configurations --config-rule-names s3-bucket-encryption-check
