# Fetch Instance Metadata Script

## Overview
This script retrieves instance metadata such as Instance ID, Instance Type, and Availability Zone. It supports both IMDSv1 and IMDSv2 and detects whether it's running in LocalStack or on a real AWS EC2 instance.

## Prerequisites
Before running the script, ensure you have the following installed and configured:
- **Docker Desktop** (for running LocalStack)
- **LocalStack** (mock AWS services locally)
- **Python** (for additional utilities if needed)
- **AWS CLI** (configured in VSCode)

## Script Explanation

### Input Argument Handling
```bash
if [[ $# -ne 2 || "$1" != "--imds-version" ]]; then
    echo "Usage: $0 --imds-version v1|v2"
    exit 1
fi
```
This checks if the correct number of arguments is provided. If not, it exits with a usage message.

### Detecting Environment (LocalStack or AWS)
```bash
METADATA_URL="http://169.254.169.254/latest/meta-data"
if curl -s --connect-timeout 1 $METADATA_URL/instance-id >/dev/null; then
    USE_LOCALSTACK=false
else
    USE_LOCALSTACK=true
fi
```
This checks if the script is running inside a real AWS instance by attempting to fetch metadata. If it fails, it assumes LocalStack is being used.

### Fetching Metadata
- **LocalStack Mode:** Uses AWS CLI with LocalStack’s endpoint.
- **IMDSv1 Mode:** Uses `curl` to fetch metadata from `http://169.254.169.254/latest/meta-data`.
- **IMDSv2 Mode:** First retrieves a session token, then uses it to get metadata.

```bash
if [ "$USE_LOCALSTACK" == "true" ]; then
    INSTANCE_ID=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].InstanceId" --output text | head -n 1)
    INSTANCE_TYPE=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].InstanceType" --output text | head -n 1)
    AVAILABILITY_ZONE=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].Placement.AvailabilityZone" --output text | head -n 1)

elif [ "$IMDS_VERSION" == "v1" ]; then
    INSTANCE_ID=$(curl -s $METADATA_URL/instance-id)
    INSTANCE_TYPE=$(curl -s $METADATA_URL/instance-type)
    AVAILABILITY_ZONE=$(curl -s $METADATA_URL/placement/availability-zone)

elif [ "$IMDS_VERSION" == "v2" ]; then
    TOKEN=$(curl -s -X PUT "$METADATA_URL/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/instance-id)
    INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/instance-type)
    AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/placement/availability-zone)
else
    echo "Invalid IMDS version. Use v1 or v2."
    exit 1
fi
```

### Handling Missing Data
```bash
INSTANCE_ID=${INSTANCE_ID:-"N/A"}
INSTANCE_TYPE=${INSTANCE_TYPE:-"N/A"}
AVAILABILITY_ZONE=${AVAILABILITY_ZONE:-"N/A"}
```
If metadata retrieval fails, default values (`N/A`) are used to prevent empty outputs.

### Output
```bash
echo "{ \"InstanceId\": \"$INSTANCE_ID\", \"InstanceType\": \"$INSTANCE_TYPE\", \"AvailabilityZone\": \"$AVAILABILITY_ZONE\" }"
```
The output is formatted as a JSON object.

## Usage
### Run in LocalStack
```bash
./fetch_metadata.sh --imds-version v1
```
OR
```bash
./fetch_metadata.sh --imds-version v2
```
### Run on AWS EC2
Ensure the script is running on an EC2 instance:
```bash
./fetch_metadata.sh --imds-version v2
```

## Troubleshooting
- **LocalStack not running?**
  ```bash
  docker start localstack
  ```
- **AWS CLI not configured?**
  ```bash
  aws configure
  ```
- **Connection issues with IMDSv2?** Ensure the instance allows IMDSv2 requests.

## Contributing
Feel free to fork and modify the script as needed!

## License
MIT License

