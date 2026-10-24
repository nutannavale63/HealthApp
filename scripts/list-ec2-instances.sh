#!/bin/bash

# Script to list all EC2 instances in the AWS account
# Usage: ./list-ec2-instances.sh [region]

set -e

AWS_REGION=${1:-us-west-2}

echo "=========================================="
echo "Listing EC2 instances in region: $AWS_REGION"
echo "=========================================="

# Get all instances
aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PublicIpAddress,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

echo ""
echo "=========================================="
echo "Detailed instance information:"
echo "=========================================="

# Get detailed information
aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --query 'Reservations[].Instances[?State.Name!=`terminated`].{ID:InstanceId,State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,Name:Tags[?Key==`Name`].Value|[0],LaunchTime:LaunchTime}' \
  --output table

echo ""
echo "To SSH into an instance:"
echo "  ./ssh-to-instance.sh <instance-id>"
echo "  or"
echo "  ssh -i ~/.ssh/bbhealthapp/bbhealthapp-key ec2-user@<public-ip>"
