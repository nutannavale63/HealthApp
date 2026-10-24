#!/bin/bash

# Script to SSH into EKS cluster nodes
# Usage: ./ssh-to-eks-nodes.sh [cluster-name] [region]

set -e

CLUSTER_NAME=${1:-bbhealthapp-cluster}
AWS_REGION=${2:-us-west-2}
KEY_NAME=${3:-bbhealthapp-key}
SSH_DIR="$HOME/.ssh/bbhealthapp"

echo "=========================================="
echo "Connecting to EKS cluster nodes: $CLUSTER_NAME"
echo "=========================================="

# Get EKS node instance IDs
echo "Fetching EKS node instances..."
NODE_INSTANCES=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table)

echo "$NODE_INSTANCES"
echo ""

# Get instance IDs as array
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No running EKS nodes found"
    exit 1
fi

# Convert to array
IFS=$'\n' read -d '' -r -a instances <<< "$INSTANCE_IDS"

echo "Found ${#instances[@]} running node(s)"
echo ""

# Select instance to connect to
if [ ${#instances[@]} -eq 1 ]; then
    INSTANCE_ID=${instances[0]}
    echo "Auto-selecting the only available node: $INSTANCE_ID"
else
    echo "Select a node to connect to:"
    select INSTANCE_ID in "${instances[@]}"; do
        if [ -n "$INSTANCE_ID" ]; then
            break
        fi
    done
fi

echo ""
echo "Connecting to node: $INSTANCE_ID"
echo "Note: EKS nodes are in private subnets, you need bastion host access"
echo ""

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0]' \
  --output json)

PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.PrivateIpAddress')

echo "Node Private IP: $PRIVATE_IP"
echo ""

# Check if bastion host exists
BASTION_IP=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=*bastion*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text 2>/dev/null || echo "")

if [ "$BASTION_IP" != "None" ] && [ -n "$BASTION_IP" ]; then
    echo "Found bastion host: $BASTION_IP"
    echo "Connecting via bastion..."
    ssh -i "$SSH_DIR/$KEY_NAME" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ProxyCommand="ssh -i $SSH_DIR/$KEY_NAME -W %h:%p ec2-user@$BASTION_IP" \
      "ec2-user@$PRIVATE_IP"
else
    echo "No bastion host found"
    echo "Direct SSH to private IP not possible without bastion"
    echo ""
    echo "Options:"
    echo "  1. Deploy a bastion host using Terraform"
    echo "  2. Use AWS Systems Manager Session Manager"
    echo "  3. Use kubectl exec to access pods instead"
    echo ""
    echo "Using kubectl exec to access node:"
    echo "  kubectl debug node/$INSTANCE_ID -it --image=nicolaka/netshoot"
fi
