#!/bin/bash

# Script to create a bastion host for secure EC2 access
# Usage: ./create-bastion-host.sh [key-name] [region]

set -e

KEY_NAME=${1:-bbhealthapp-key}
AWS_REGION=${2:-us-west-2}
VPC_ID=${3:-}
SUBNET_ID=${4:-}

echo "=========================================="
echo "Creating bastion host for secure access"
echo "=========================================="

# Get VPC ID if not provided
if [ -z "$VPC_ID" ]; then
    echo "Fetching VPC ID..."
    VPC_ID=$(aws ec2 describe-vpcs \
      --region "$AWS_REGION" \
      --filters "Name=tag:Name,Values=*bbhealthapp*" \
      --query 'Vpcs[0].VpcId' \
      --output text)
    
    if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
        echo "Error: Could not find VPC. Please provide VPC_ID as third argument"
        exit 1
    fi
    echo "Using VPC: $VPC_ID"
fi

# Get public subnet if not provided
if [ -z "$SUBNET_ID" ]; then
    echo "Fetching public subnet..."
    SUBNET_ID=$(aws ec2 describe-subnets \
      --region "$AWS_REGION" \
      --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" \
      --query 'Subnets[0].SubnetId' \
      --output text)
    
    if [ "$SUBNET_ID" == "None" ] || [ -z "$SUBNET_ID" ]; then
        echo "Error: Could not find public subnet. Please provide SUBNET_ID as fourth argument"
        exit 1
    fi
    echo "Using subnet: $SUBNET_ID"
fi

# Get security group ID
echo "Creating security group for bastion..."
SG_ID=$(aws ec2 create-security-group \
  --group-name "bbhealthapp-bastion-sg" \
  --description "Security group for BBHealthApp bastion host" \
  --vpc-id "$VPC_ID" \
  --region "$AWS_REGION" \
  --query 'GroupId' \
  --output text)

# Allow SSH access
echo "Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region "$AWS_REGION"

# Allow all outbound traffic
aws ec2 authorize-security-group-egress \
  --group-id "$SG_ID" \
  --protocol -1 \
  --port -1 \
  --cidr 0.0.0.0/0 \
  --region "$AWS_REGION"

# Create bastion instance
echo "Launching bastion instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --count 1 \
  --instance-type t3.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --subnet-id "$SUBNET_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=bbhealthapp-bastion},{Key=Project,Value=bbhealthapp}]" \
  --region "$AWS_REGION" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Bastion instance launched: $INSTANCE_ID"
echo "Waiting for instance to be running..."

aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "=========================================="
echo "Bastion host created successfully!"
echo "=========================================="
echo ""
echo "Instance Details:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"
echo "  Security Group: $SG_ID"
echo ""
echo "Next steps:"
echo "  1. Update SSH config with bastion IP: $PUBLIC_IP"
echo "  2. SSH to bastion: ssh -i ~/.ssh/bbhealthapp/$KEY_NAME ec2-user@$PUBLIC_IP"
echo "  3. Use bastion to access private instances"
echo ""
echo "Update your SSH config (~/.ssh/config):"
echo "  Host bbhealthapp-bastion"
echo "      HostName $PUBLIC_IP"
echo "      User ec2-user"
echo "      IdentityFile ~/.ssh/bbhealthapp/$KEY_NAME"
