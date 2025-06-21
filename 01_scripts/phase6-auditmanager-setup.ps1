# Phase 6 – AWS Audit Manager Setup Script

# 1. Ensure your S3 bucket exists (for evidence & reports)
$bucketName = "security-compliance-config-<date>-<random>"   # Replace with actual bucket name
$region     = "ap-south-1"
Write-Host "Ensuring S3 bucket $bucketName exists..."
aws s3 mb s3://$bucketName --region $region 2>$null

# 2. Prompt user to complete one-time console setup
Write-Host ""
Write-Host "Please complete the one-time AWS Audit Manager console setup in the browser:"
Write-Host "https://console.aws.amazon.com/auditmanager/home?region=$region#/settings"
Read-Host "Press Enter to continue once done..."

# 3. Fetch the AWS-managed CIS framework ARN
Write-Host "Fetching AWS-managed CIS framework ARN..."
$cisArn = & aws auditmanager list-assessment-frameworks `
  --framework-type Standard `
  --query "frameworkMetadataList[?contains(name, 'CIS AWS Foundations')].frameworkArn" `
  --output text
Write-Host "Found CIS framework ARN:" $cisArn

# 4. Create the CIS-Assessment
Write-Host "Creating CIS-Assessment..."
$accountId = aws sts get-caller-identity --query Account --output text
$assessment = & aws auditmanager create-assessment `
  --name "CIS-Assessment" `
  --framework-arn $cisArn `
  --scope awsAccounts=[{accountId='$accountId'}] `
  --roles roleArn="arn:aws:iam::$accountId:role/AWSAuditManagerRole",roleType="PROCESS_OWNER" `
  --assessment-reports-destination destinationType="S3",destination=$bucketName

# 5. Output the new Assessment ARN & ID
$assessment | ConvertFrom-Json | ForEach-Object {
  Write-Host "Assessment created:"
  Write-Host "  ID:  " $_.assessmentId
  Write-Host "  ARN: " $_.assessmentArn
}

# 6. Verify the assessment status
Write-Host "Checking assessment status..."
aws auditmanager list-assessments `
  --query "assessmentMetadataList[?name=='CIS-Assessment'].[assessmentId, status]" `
  --output table
