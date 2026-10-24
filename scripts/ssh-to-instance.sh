#!/bin/bash

# Script to SSH into an EC2 instance
# Usage: ./ssh-to-instance.sh <instance-id> [region] [key-name]

set -e

INSTANCE_ID=$1
AWS_REGION=${2:-us-west-2}
KEY_NAME=${3:-bbhealthapp-key}
SSH_DIR="$HOME/.ssh/bbhealthapp"

if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Instance ID is required"
    echo "Usage: $0 <instance-id> [region] [key-name]"
    echo ""
    echo "Available instances:"
    ./list-ec2-instances.sh "$AWS_REGION"
    exit 1
fi

echo "=========================================="
echo "Connecting to EC2 instance: $INSTANCE_ID"
echo "=========================================="

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0]' \
  --output json)

STATE=$(echo "$INSTANCE_INFO" | jq -r '.State.Name')
PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.PrivateIpAddress')

if [ "$STATE" != "running" ]; then
    echo "Error: Instance is not running (current state: $STATE)"
    exit 1
fi

if [ -z "$PUBLIC_IP" ]; then
    echo "Warning: Instance has no public IP"
    echo "Private IP: $PRIVATE_IP"
    echo "This instance may be in a private subnet and require bastion host access"
    echo ""
    read -p "Continue with private IP? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    TARGET_IP=$PRIVATE_IP
else
    TARGET_IP=$PUBLIC_IP
fi

echo "Instance State: $STATE"
echo "Target IP: $TARGET_IP"
echo "SSH Key: $SSH_DIR/$KEY_NAME"
echo ""

# SSH into the instance
ssh -i "$SSH_DIR/$KEY_NAME" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "ec2-user@$TARGET_IP"
