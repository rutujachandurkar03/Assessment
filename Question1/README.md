# EC2 Metadata Fetch Script

This script retrieves metadata for an EC2 instance, including the **Instance ID, Instance Type, and Availability Zone**. It works in both:
- **AWS EC2 instances** (supports both IMDSv1 & IMDSv2)
- **LocalStack** (via AWS CLI)

## Features
✅ Supports **IMDSv1** and **IMDSv2**
✅ Automatically detects **LocalStack vs. AWS**
✅ Outputs metadata in **JSON format**
✅ Provides **error handling** to prevent failures
✅ Works seamlessly in **AWS Cloud & Local Dev Environments**

## Prerequisites
- **AWS CLI** installed and configured
- **Bash** shell environment (Linux, macOS, WSL, Git Bash on Windows)
- (For LocalStack) **LocalStack running on `localhost:4566`**

## Installation
Clone the repository:
```sh
git clone https://github.com/your-username/ec2-metadata-fetch.git
cd ec2-metadata-fetch
```
Give execution permissions to the script:
```sh
chmod +x fetch_metadata.sh
```

## Usage
### Fetch Metadata on AWS EC2 (IMDSv1)
```sh
./fetch_metadata.sh --imds-version v1
```
### Fetch Metadata on AWS EC2 (IMDSv2)
```sh
./fetch_metadata.sh --imds-version v2
```
### Fetch Metadata on LocalStack
```sh
./fetch_metadata.sh --imds-version v1  # Works since LocalStack doesn't support IMDS
```

## Example Output
```json
{ "InstanceId": "i-12345678", "InstanceType": "t2.micro", "AvailabilityZone": "us-east-1a" }
```

## How It Works
1. **Checks the environment**: Attempts to connect to `169.254.169.254`. If unavailable, assumes LocalStack.
2. **For LocalStack**, it fetches instance details via AWS CLI (`aws ec2 describe-instances`).
3. **For AWS EC2**:
   - **IMDSv1**: Uses `curl` to retrieve metadata directly.
   - **IMDSv2**: First fetches a token, then retrieves metadata with the token.
4. **Outputs metadata in JSON format**.

## Script
```bash
#!/bin/bash

# Check input arguments
if [[ $# -ne 2 || "$1" != "--imds-version" ]]; then
    echo "Usage: $0 --imds-version v1|v2"
    exit 1
fi

IMDS_VERSION=$2
METADATA_URL="http://169.254.169.254/latest/meta-data"

# Detect if running in LocalStack (by checking IMDS reachability)
if curl -s --connect-timeout 1 $METADATA_URL/instance-id >/dev/null; then
    USE_LOCALSTACK=false
else
    USE_LOCALSTACK=true
fi

# Fetch metadata
if [ "$USE_LOCALSTACK" == "true" ]; then
    echo "Running in LocalStack. Using AWS CLI to fetch metadata..."
    
    INSTANCE_ID=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].InstanceId" --output text | head -n 1)
    INSTANCE_TYPE=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].InstanceType" --output text | head -n 1)
    AVAILABILITY_ZONE=$(aws ec2 describe-instances --endpoint-url=http://localhost:4566 --query "Reservations[*].Instances[*].Placement.AvailabilityZone" --output text | head -n 1)

elif [ "$IMDS_VERSION" == "v1" ]; then
    echo "Fetching metadata using IMDSv1..."
    
    INSTANCE_ID=$(curl -s $METADATA_URL/instance-id)
    INSTANCE_TYPE=$(curl -s $METADATA_URL/instance-type)
    AVAILABILITY_ZONE=$(curl -s $METADATA_URL/placement/availability-zone)

elif [ "$IMDS_VERSION" == "v2" ]; then
    echo "Fetching metadata using IMDSv2..."
    
    TOKEN=$(curl -s -X PUT "$METADATA_URL/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/instance-id)
    INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/instance-type)
    AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $METADATA_URL/placement/availability-zone)
else
    echo "Invalid IMDS version. Use v1 or v2."
    exit 1
fi

# Ensure variables are not empty (handle failures)
INSTANCE_ID=${INSTANCE_ID:-"N/A"}
INSTANCE_TYPE=${INSTANCE_TYPE:-"N/A"}
AVAILABILITY_ZONE=${AVAILABILITY_ZONE:-"N/A"}

# Output metadata in JSON format
echo "{ \"InstanceId\": \"$INSTANCE_ID\", \"InstanceType\": \"$INSTANCE_TYPE\", \"AvailabilityZone\": \"$AVAILABILITY_ZONE\" }"
```

## Troubleshooting
**Issue: `curl: Failed to connect to 169.254.169.254`**
- Ensure you are running inside an **AWS EC2 instance**.
- If using LocalStack, metadata retrieval works via **AWS CLI only**.

**Issue: Empty JSON output `{}`**
- The script ensures no empty values; check **IAM permissions** if using AWS CLI.

## License
This project is licensed under the MIT License.

## Author
👤 **Your Name**  
🔗 GitHub: [your-username](https://github.com/your-username)

