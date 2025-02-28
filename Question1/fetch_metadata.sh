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
