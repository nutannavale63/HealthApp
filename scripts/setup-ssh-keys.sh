#!/bin/bash

# Script to set up SSH keys for AWS EC2 access
# Usage: ./setup-ssh-keys.sh [key-name]

set -e

KEY_NAME=${1:-bbhealthapp-key}
SSH_DIR="$HOME/.ssh/bbhealthapp"

echo "=========================================="
echo "Setting up SSH keys for AWS EC2 access"
echo "=========================================="

# Create SSH directory
echo "Creating SSH directory: $SSH_DIR"
mkdir -p "$SSH_DIR"

# Generate SSH key pair
echo "Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/$KEY_NAME" -N "" -C "$KEY_NAME@bbhealthapp"

# Set proper permissions
echo "Setting permissions..."
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/$KEY_NAME"
chmod 644 "$SSH_DIR/$KEY_NAME.pub"

# Import key to AWS
echo "Importing key to AWS..."
aws ec2 import-key-pair \
  --key-name "$KEY_NAME" \
  --public-key-material fileb://"$SSH_DIR/$KEY_NAME.pub" \
  --region us-west-2

# Verify key import
echo "Verifying key import..."
aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region us-west-2

echo "=========================================="
echo "SSH key setup completed successfully!"
echo "=========================================="
echo ""
echo "Key details:"
echo "  Key name: $KEY_NAME"
echo "  Private key: $SSH_DIR/$KEY_NAME"
echo "  Public key: $SSH_DIR/$KEY_NAME.pub"
echo ""
echo "Next steps:"
echo "  1. Update SSH config: ./setup-ssh-config.sh"
echo "  2. List EC2 instances: ./list-ec2-instances.sh"
echo "  3. SSH to instance: ./ssh-to-instance.sh <instance-id>"
