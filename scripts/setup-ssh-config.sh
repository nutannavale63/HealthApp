#!/bin/bash

# Script to set up SSH configuration for AWS EC2 instances
# Usage: ./setup-ssh-config.sh

set -e

KEY_NAME=${1:-bbhealthapp-key}
SSH_DIR="$HOME/.ssh/bbhealthapp"
SSH_CONFIG="$HOME/.ssh/config"

echo "=========================================="
echo "Setting up SSH configuration"
echo "=========================================="

# Create SSH config backup
if [ -f "$SSH_CONFIG" ]; then
    echo "Backing up existing SSH config..."
    cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Add SSH configuration
echo "Adding SSH configuration for BBHealthApp..."

cat >> "$SSH_CONFIG" << EOF

# BBHealthApp AWS Instances - Auto-generated
# Generated on: $(date)

# Bastion host for secure access
Host bbhealthapp-bastion
    HostName <BASTION_PUBLIC_IP>
    User ec2-user
    IdentityFile $SSH_DIR/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# EKS nodes (accessed via bastion)
Host bbhealthapp-eks-node-*
    ProxyJump bbhealthapp-bastion
    User ec2-user
    IdentityFile $SSH_DIR/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Direct EC2 access
Host bbhealthapp-ec2-*
    User ec2-user
    IdentityFile $SSH_DIR/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# Set proper permissions
chmod 600 "$SSH_CONFIG"

echo "=========================================="
echo "SSH configuration completed!"
echo "=========================================="
echo ""
echo "Configuration added to: $SSH_CONFIG"
echo ""
echo "Manual steps required:"
echo "  1. Edit $SSH_CONFIG"
echo "  2. Replace <BASTION_PUBLIC_IP> with actual bastion IP"
echo "  3. Add specific host entries for your EC2 instances"
echo ""
echo "Example host entry:"
echo "  Host my-instance"
echo "      HostName 1.2.3.4"
echo "      User ec2-user"
echo "      IdentityFile $SSH_DIR/$KEY_NAME"
