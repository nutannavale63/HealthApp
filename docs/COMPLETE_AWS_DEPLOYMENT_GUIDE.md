# Complete AWS Deployment Guide for BBHealthApp

This guide provides a detailed, step-by-step process for deploying the BBHealthApp to AWS, including infrastructure setup, application deployment, and SSH access to EC2 instances.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Account Setup](#aws-account-setup)
3. [Infrastructure Deployment with Terraform](#infrastructure-deployment-with-terraform)
4. [Docker Image Management](#docker-image-management)
5. [Application Deployment with Kubernetes](#application-deployment-with-kubernetes)
6. [SSH Access to EC2 Instances](#ssh-access-to-ec2-instances)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

Install the following tools on your local machine:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-macosx.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
brew install terraform

# kubectl
brew install kubectl

# Helm
brew install helm

# Docker
brew install --cask docker

# jq (for JSON parsing)
brew install jq
```

### Verify Installations

```bash
aws --version      # Should be 2.x.x
terraform --version # Should be 1.x.x
kubectl version --client
helm version
docker --version
jq --version
```

---

## AWS Account Setup

### Step 1: Create AWS Account

If you don't have an AWS account:
1. Go to https://aws.amazon.com/
2. Click "Create an AWS Account"
3. Follow the registration process
4. Set up MFA (Multi-Factor Authentication) for security

### Step 2: Configure IAM User

**Best Practice:** Create an IAM user instead of using root account.

```bash
# Log into AWS Console
# Navigate to IAM > Users > Create user

# Create user with AdministratorAccess policy
# Or create custom policy with minimum required permissions
```

### Step 3: Configure AWS CLI

```bash
# Configure AWS CLI with your IAM user credentials
aws configure

# You'll be prompted for:
# AWS Access Key ID: [paste your access key]
# AWS Secret Access Key: [paste your secret key]
# Default region name: us-west-2
# Default output format: json
```

### Step 4: Verify AWS Configuration

```bash
# Verify your identity
aws sts get-caller-identity

# Expected output:
# {
#   "UserId": "AIDAI...",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

---

## Infrastructure Deployment with Terraform

### Step 1: Navigate to Terraform Directory

```bash
cd /Users/ishika/CascadeProjects/windsurf-project-3/terraform
```

### Step 2: Configure Terraform Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the file with your specific values
nano terraform.tfvars
```

**Key variables to configure:**

```hcl
# AWS Configuration
aws_region = "us-west-2"                    # Your preferred AWS region
environment = "dev"                        # dev, staging, or prod
project_name = "bbhealthapp"                # Project name

# RDS Configuration
db_password = "YourSecurePassword123!"     # STRONG password required
db_instance_class = "db.t3.micro"           # Development: db.t3.micro, Production: db.t3.medium or larger

# EKS Configuration
node_instance_type = "t3.medium"            # EC2 instance type for EKS nodes
node_desired_size = 3                      # Number of nodes
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the required Terraform providers and modules.

### Step 4: Review Terraform Plan

```bash
terraform plan
```

**Review the output carefully:**
- Check which resources will be created
- Verify the configuration values
- Ensure costs are acceptable

### Step 5: Apply Infrastructure

```bash
terraform apply
```

**Type `yes` when prompted to confirm.**

**This will create:**
- VPC with public and private subnets
- EKS Kubernetes cluster
- RDS MySQL database
- ECR repositories for Docker images
- IAM roles and security groups
- CloudWatch log groups

**Expected duration:** 15-25 minutes

### Step 6: Save Terraform Outputs

```bash
# Save outputs for later use
terraform output -json > ../infrastructure-outputs.json

# View important outputs
terraform output rds_endpoint
terraform output ecr_repository_urls
terraform output configure_kubectl
```

---

## Docker Image Management

### Step 1: Configure Docker for ECR

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com"

echo "Your ECR Registry: $ECR_REGISTRY"
```

### Step 2: Login to ECR

```bash
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

### Step 3: Build Docker Images

```bash
cd /Users/ishika/CascadeProjects/windsurf-project-3

# Build all images using the provided script
./scripts/build-and-push-ecr.sh us-west-2 default
```

**This script will:**
1. Build Docker images for all services
2. Tag images for ECR
3. Push images to ECR repositories
4. Display repository URLs

### Step 4: Verify Images in ECR

```bash
# List repositories
aws ecr describe-repositories --region us-west-2

# Describe images in a repository
aws ecr describe-images --repository-name bbhealthapp-frontend --region us-west-2
```

---

## Application Deployment with Kubernetes

### Step 1: Configure kubectl for EKS

```bash
# Update kubeconfig
aws eks update-kubeconfig --name bbhealthapp-cluster --region us-west-2

# Verify connection
kubectl get nodes

# Expected output:
# NAME                            STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123.us-west-2...     Ready    <none>   5m    v1.28.x
# ip-10-0-2-123.us-west-2...     Ready    <none>   5m    v1.28.x
# ip-10-0-3-123.us-west-2...     Ready    <none>   5m    v1.28.x
```

### Step 2: Create Kubernetes Namespace

```bash
kubectl create namespace bbhealthapp
```

### Step 3: Create Database Secret

```bash
# Get RDS endpoint from Terraform
cd terraform
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
cd ..

# Create secret with database credentials
kubectl create secret generic bbhealthapp-db-secret \
  --from-literal=db-host=$RDS_ENDPOINT \
  --from-literal=db-username=admin \
  --from-literal=db-password=YourSecurePassword123! \
  -n bbhealthapp

# Verify secret
kubectl get secret bbhealthapp-db-secret -n bbhealthapp
```

### Step 4: Update Helm Values

```bash
cd /Users/ishika/CascadeProjects/windsurf-project-3

# Get your ECR registry
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com"

# Edit Helm values
nano helm/bbhealthapp/values.yaml
```

**Update these values:**

```yaml
# Line 11: Update image registry
image:
  registry: "123456789012.dkr.ecr.us-west-2.amazonaws.com"  # Your ECR registry
  tag: "latest"

# Line 132: Update domain name
ingress:
  hosts:
    - host: "your-domain.com"  # Your actual domain
```

### Step 5: Deploy Application with Helm

```bash
# Add required Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy the application
helm install bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --set image.registry=$ECR_REGISTRY \
  --set ingress.hosts[0].host=your-domain.com
```

### Step 6: Monitor Deployment

```bash
# Watch pod status
kubectl get pods -n bbhealthapp -w

# Check pod details
kubectl describe pod -n bbhealthapp

# View logs
kubectl logs -f deployment/frontend -n bbhealthapp
kubectl logs -f deployment/master-service -n bbhealthapp
kubectl logs -f deployment/register-service -n bbhealthapp
kubectl logs -f deployment/document-service -n bbhealthapp
```

### Step 7: Verify Services

```bash
# Check services
kubectl get svc -n bbhealthapp

# Check ingress
kubectl get ingress -n bbhealthapp

# Get Load Balancer URL
kubectl get ingress bbhealthapp-frontend -n bbhealthapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 8: Access Application

```bash
# Get the ALB URL
ALB_URL=$(kubectl get ingress bbhealthapp-frontend -n bbhealthapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_URL"
```

Open the URL in your browser to access the application.

---

## SSH Access to EC2 Instances

### Step 1: Create SSH Key Pair

```bash
# Create SSH key directory
mkdir -p ~/.ssh/bbhealthapp

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/bbhealthapp/bbhealthapp-key -N ""

# Set proper permissions
chmod 700 ~/.ssh/bbhealthapp
chmod 600 ~/.ssh/bbhealthapp/bbhealthapp-key
chmod 644 ~/.ssh/bbhealthapp/bbhealthapp-key.pub
```

### Step 2: Add SSH Key to AWS

```bash
# Import key to AWS
aws ec2 import-key-pair \
  --key-name bbhealthapp-key \
  --public-key-material fileb://~/.ssh/bbhealthapp/bbhealthapp-key.pub \
  --region us-west-2

# Verify key import
aws ec2 describe-key-pairs --key-names bbhealthapp-key --region us-west-2
```

### Step 3: Create SSH Configuration

```bash
# Create SSH config file
cat > ~/.ssh/config << 'EOF'
# BBHealthApp AWS Instances
Host bbhealthapp-bastion
    HostName <BASTION_PUBLIC_IP>
    User ec2-user
    IdentityFile ~/.ssh/bbhealthapp/bbhealthapp-key
    StrictHostKeyChecking no

Host bbhealthapp-eks-node*
    ProxyJump bbhealthapp-bastion
    User ec2-user
    IdentityFile ~/.ssh/bbhealthapp/bbhealthapp-key
    StrictHostKeyChecking no
EOF

# Set permissions
chmod 600 ~/.ssh/config
```

### Step 4: Deploy Bastion Host (Optional)

For secure access to private resources, deploy a bastion host:

```bash
cd /Users/ishika/CascadeProjects/windsurf-project-3/terraform

# Add bastion host configuration to Terraform
# (See terraform/bastion.tf for configuration)

terraform apply
```

### Step 5: SSH into EC2 Instances

```bash
# SSH into bastion host
ssh bbhealthapp-bastion

# SSH into EKS nodes (via bastion)
ssh bbhealthapp-eks-node-1

# Direct SSH to EC2 instances
ssh -i ~/.ssh/bbhealthapp/bbhealthapp-key ec2-user@<INSTANCE_PUBLIC_IP>
```

### Step 6: SSH Management Scripts

Use the provided scripts for easy SSH access:

```bash
# List all EC2 instances
./scripts/list-ec2-instances.sh

# SSH into specific instance
./scripts/ssh-to-instance.sh <INSTANCE_ID>

# SSH into EKS nodes
./scripts/ssh-to-eks-nodes.sh
```

---

## Monitoring and Maintenance

### Step 1: Set Up CloudWatch Alarms

```bash
# Create CloudWatch alarm for CPU utilization
aws cloudwatch put-metric-alarm \
  --alarm-name bbhealthapp-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EKS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ClusterName,Value=bbhealthapp-cluster
```

### Step 2: View Logs

```bash
# Application logs
kubectl logs -f deployment/frontend -n bbhealthapp

# EKS control plane logs
aws logs tail /aws/eks/bbhealthapp-cluster/cluster --follow --region us-west-2

# RDS slow query logs
aws rds describe-db-log-files --db-instance-identifier bbhealthapp-db --region us-west-2
```

### Step 3: Backup Database

```bash
# Create manual RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier bbhealthapp-db \
  --db-snapshot-identifier bbhealthapp-db-manual-$(date +%Y%m%d-%H%M%S) \
  --region us-west-2

# List snapshots
aws rds describe-db-snapshots --db-instance-identifier bbhealthapp-db --region us-west-2
```

### Step 4: Scale Application

```bash
# Scale deployment
kubectl scale deployment frontend --replicas=3 -n bbhealthapp

# Enable Horizontal Pod Autoscaler
kubectl autoscale deployment frontend \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n bbhealthapp
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n bbhealthapp

# Common causes:
# - Image pull errors: Check ECR permissions
# - Resource limits: Check node capacity
# - Config errors: Check environment variables
```

#### Issue 2: Database Connection Failed

```bash
# Check RDS endpoint
aws rds describe-db-instances --db-instance-identifier bbhealthapp-db

# Test connectivity from pod
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -n bbhealthapp
nc -zv <RDS_ENDPOINT> 3306

# Check security groups
aws ec2 describe-security-groups --filters Name=group-name,Values=*bbhealthapp*
```

#### Issue 3: SSH Connection Failed

```bash
# Check security group allows SSH (port 22)
aws ec2 describe-security-groups --group-ids <SECURITY_GROUP_ID>

# Check instance is running
aws ec2 describe-instances --instance-ids <INSTANCE_ID>

# Check key pair is correct
aws ec2 describe-key-pairs --key-names bbhealthapp-key
```

#### Issue 4: Ingress Not Working

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress status
kubectl describe ingress -n bbhealthapp

# Check security group allows HTTP/HTTPS
aws ec2 describe-security-groups --filters Name=group-name,Values=*bbhealthapp*
```

### Emergency Rollback

```bash
# Rollback Helm release
helm rollback bbhealthapp -n bbhealthapp

# Rollback to specific revision
helm rollback bbhealthapp 2 -n bbhealthapp

# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier bbhealthapp-db-restored \
  --db-snapshot-identifier bbhealthapp-db-manual-<timestamp> \
  --region us-west-2
```

---

## Cost Management

### Estimate Costs Before Deployment

```bash
# Use AWS Pricing Calculator
# https://calculator.aws/

# Typical monthly costs (us-west-2):
# - EKS cluster: $73/month
# - EKS nodes (3x t3.medium): ~$90/month
# - RDS (db.t3.micro): ~$15/month
# - ALB: ~$18/month
# - ECR: ~$0.10/GB/month
# - CloudWatch Logs: ~$0.50/GB
# Total: ~$200-250/month for development
```

### Cost Optimization Tips

1. **Use Spot Instances** for non-critical workloads
2. **Enable Auto-scaling** to scale down when not in use
3. **Use Reserved Instances** for predictable workloads
4. **Set up Budget Alerts** to monitor spending
5. **Clean up unused resources** regularly

---

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use IAM roles** instead of access keys in applications
3. **Enable encryption** for all data at rest and in transit
4. **Use VPC endpoints** for private AWS service access
5. **Enable MFA** on all IAM users
6. **Regularly rotate** credentials and certificates
7. **Use AWS Secrets Manager** for sensitive data
8. **Enable VPC Flow Logs** for network monitoring

---

## Next Steps

1. **Set up CI/CD pipeline** (GitHub Actions, GitLab CI)
2. **Configure monitoring** (Prometheus, Grafana)
3. **Set up log aggregation** (ELK Stack, CloudWatch Logs)
4. **Implement automated testing**
5. **Set up disaster recovery procedures**
6. **Configure backup strategies**
7. **Implement security scanning** (Trivy, Snyk)

---

## Support and Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

For specific issues, check the logs in CloudWatch and Kubernetes events.
