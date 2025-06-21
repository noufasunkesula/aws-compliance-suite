# Create the configuration recorder JSON file
@"
{
  "name": "default",
  "roleARN": "arn:aws:iam::<YourAccountID>:role/<YourRoleName>",
  "recordingGroup": {
    "allSupported": true,
    "includeGlobalResourceTypes": true
  }
}
"@ | Out-File .\config-recorder.json -Encoding ascii

# Create the configuration recorder
aws configservice put-configuration-recorder `
  --configuration-recorder file://config-recorder.json

# Set up the delivery channel (replace the bucket name)
aws configservice put-delivery-channel `
  --delivery-channel name=default,s3BucketName=<YourS3BucketName>

# Start the configuration recorder
aws configservice start-configuration-recorder `
  --configuration-recorder-name default

# Check the status of the recorder
aws configservice describe-configuration-recorder-status
