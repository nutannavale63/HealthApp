# SSH Access Quick Start Guide

This guide helps you quickly set up SSH access to your AWS EC2 instances within the BBHealthApp project.

## Quick Setup (5 Minutes)

### Step 1: Set Up SSH Keys

```bash
cd /Users/ishika/CascadeProjects/windsurf-project-3

# Generate SSH keys and import to AWS
./scripts/setup-ssh-keys.sh
```

This will:
- Generate SSH key pair in `~/.ssh/bbhealthapp/`
- Import the public key to AWS EC2
- Display key details

### Step 2: Configure SSH

```bash
# Set up SSH configuration
./scripts/setup-ssh-config.sh
```

This will add SSH configuration to `~/.ssh/config`.

### Step 3: Deploy Infrastructure with Bastion Host

```bash
cd terraform

# Ensure bastion host is enabled in terraform.tfvars
# enable_bastion_host = true

# Apply Terraform
terraform apply
```

### Step 4: Get Bastion Host IP

```bash
# Get bastion host public IP
terraform output bastion_public_ip

# Or use the SSH command directly
terraform output bastion_ssh_command
```

### Step 5: SSH to Bastion Host

```bash
# Using the SSH command from Terraform output
terraform output bastion_ssh_command | xargs

# Or manually
ssh -i ~/.ssh/bbhealthapp/bbhealthapp-key ec2-user@<BASTION_PUBLIC_IP>
```

## SSH Access Methods

### Method 1: Using Provided Scripts

```bash
# List all EC2 instances
./scripts/list-ec2-instances.sh

# SSH to specific instance by ID
./scripts/ssh-to-instance.sh <instance-id>

# SSH to EKS nodes
./scripts/ssh-to-eks-nodes.sh
```

### Method 2: Using SSH Config

```bash
# SSH to bastion host
ssh bbhealthapp-bastion

# SSH to EKS nodes (via bastion)
ssh bbhealthapp-eks-node-1
```

### Method 3: Direct SSH

```bash
# SSH to any EC2 instance
ssh -i ~/.ssh/bbhealthapp/bbhealthapp-key ec2-user@<PUBLIC_IP>
```

## Accessing Different Instance Types

### EKS Cluster Nodes

```bash
# Option 1: Via bastion (recommended)
./scripts/ssh-to-eks-nodes.sh bbhealthapp-cluster us-west-2

# Option 2: Using kubectl debug
kubectl debug node/<node-name> -it --image=nicolaka/netshoot
```

### Application Pods

```bash
# Get shell in running pod
kubectl exec -it <pod-name> -n bbhealthapp -- /bin/bash

# Example: Frontend pod
kubectl exec -it deployment/frontend -n bbhealthapp -- /bin/bash
```

### RDS Database

```bash
# Connect via bastion
ssh bbhealthapp-bastion
# Then from bastion:
mysql -h <RDS_ENDPOINT> -u admin -p binarybrainspg
```

## Security Best Practices

### 1. Restrict SSH Access

Edit `terraform/terraform.tfvars`:

```hcl
# Restrict to your IP only
bastion_allowed_cidr_blocks = ["YOUR.IP.ADDRESS.HERE/32"]
```

### 2. Use Session Manager (No SSH Required)

```bash
# Install Session Manager plugin
brew install session-manager-plugin

# Connect without SSH
aws ssm start-session --target <instance-id> --region us-west-2
```

### 3. Enable Bastion Host Only When Needed

```hcl
# Disable bastion when not in use
enable_bastion_host = false
```

### 4. Use SSH Keys Only

Never use password authentication. SSH keys are already configured.

## Troubleshooting SSH Issues

### Issue: Permission Denied

```bash
# Check key permissions
chmod 600 ~/.ssh/bbhealthapp/bbhealthapp-key
chmod 644 ~/.ssh/bbhealthapp/bbhealthapp-key.pub
```

### Issue: Host Key Verification Failed

```bash
# Remove old host key
ssh-keygen -R <HOST_IP>

# Or disable strict checking (not recommended for production)
ssh -o StrictHostKeyChecking=no ec2-user@<HOST_IP>
```

### Issue: Connection Timed Out

```bash
# Check security group allows SSH (port 22)
aws ec2 describe-security-groups --group-ids <SG_ID>

# Check instance is running
aws ec2 describe-instances --instance-ids <INSTANCE_ID>

# Check network ACLs
aws ec2 describe-network-acls --filters Name=vpc-id,Values=<VPC_ID>
```

### Issue: Instance in Private Subnet

```bash
# Use bastion host as jump server
ssh -J ec2-user@<BASTION_IP> ec2-user@<PRIVATE_IP>

# Or use Session Manager
aws ssm start-session --target <instance-id>
```

## Advanced SSH Configuration

### SSH Tunneling

```bash
# Tunnel local port to remote database
ssh -L 3306:<RDS_ENDPOINT>:3306 ec2-user@<BASTION_IP>

# Now connect to localhost:3306 instead of remote
mysql -h 127.0.0.1 -u admin -p binarybrainspg
```

### SSH Agent Forwarding

```bash
# Add key to SSH agent
ssh-add ~/.ssh/bbhealthapp/bbhealthapp-key

# Enable agent forwarding in SSH config
Host bbhealthapp-bastion
    ForwardAgent yes
```

### SCP File Transfer

```bash
# Copy file to instance
scp -i ~/.ssh/bbhealthapp/bbhealthapp-key local-file.txt ec2-user@<INSTANCE_IP>:~/

# Copy file from instance
scp -i ~/.ssh/bbhealthapp/bbhealthapp-key ec2-user@<INSTANCE_IP>:~/remote-file.txt ./
```

## SSH Script Reference

### setup-ssh-keys.sh
- Generates SSH key pair
- Imports public key to AWS
- Usage: `./scripts/setup-ssh-keys.sh [key-name]`

### setup-ssh-config.sh
- Creates SSH configuration
- Adds host entries
- Usage: `./scripts/setup-ssh-config.sh`

### list-ec2-instances.sh
- Lists all EC2 instances
- Shows instance details
- Usage: `./scripts/list-ec2-instances.sh [region]`

### ssh-to-instance.sh
- SSH to specific instance
- Auto-detects IP address
- Usage: `./scripts/ssh-to-instance.sh <instance-id> [region] [key-name]`

### ssh-to-eks-nodes.sh
- SSH to EKS cluster nodes
- Requires bastion host
- Usage: `./scripts/ssh-to-eks-nodes.sh [cluster-name] [region]`

### create-bastion-host.sh
- Creates bastion host manually
- Alternative to Terraform
- Usage: `./scripts/create-bastion-host.sh [key-name] [region]`

## Next Steps

1. **Set up SSH keys**: Run `./scripts/setup-ssh-keys.sh`
2. **Deploy infrastructure**: Run `terraform apply` in terraform directory
3. **Configure SSH**: Run `./scripts/setup-ssh-config.sh`
4. **Test access**: SSH to bastion host
5. **Access resources**: Use bastion to access private resources

## Support

For issues with SSH access:
1. Check AWS security group rules
2. Verify instance is running
3. Ensure SSH key is imported to AWS
4. Check network ACLs and route tables
5. Review CloudWatch logs for connection attempts
