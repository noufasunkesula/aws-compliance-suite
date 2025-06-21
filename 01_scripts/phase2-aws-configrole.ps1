# Create trust policy file for AWS Config
@"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "config.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
"@ | Out-File .\trust-policy.json -Encoding ascii

# Create the IAM Role
aws iam create-role `
  --role-name <YourRoleName> `
  --assume-role-policy-document file://trust-policy.json

# Attach the AWS Config managed policy
aws iam attach-role-policy `
  --role-name <YourRoleName> `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWS_ConfigRole

# Optional: Verify the role
aws iam get-role --role-name <YourRoleName>

# Optional: List attached policies
aws iam list-attached-role-policies --role-name <YourRoleName>
