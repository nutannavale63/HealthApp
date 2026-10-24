# AWS Deployment Guide for BBHealthApp

This comprehensive guide covers deploying the BBHealthApp to AWS using EKS, RDS, and ECR.

## Prerequisites

- AWS account with appropriate IAM permissions
- AWS CLI installed and configured
- Terraform installed (>= 1.0)
- kubectl installed
- Helm installed (>= 3.0)
- Docker installed
- Domain name registered (for production SSL/TLS)

## Architecture Overview

```
                    Internet
                       |
                AWS Load Balancer (ALB)
                       |
              EKS Cluster (Kubernetes)
                       |
        +-------------+-------------+-------------+
        |             |             |             |
   Frontend    Master Service  Register Service  Document Service
        |             |             |             |
        +-------------+-------------+-------------+
                       |
                   AWS RDS (MySQL)
```

## Step 1: Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Set your default region
aws configure set region us-west-2
```

## Step 2: Deploy Infrastructure with Terraform

### 2.1 Configure Terraform Variables

```bash
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Set a secure db_password
nano terraform.tfvars
```

### 2.2 Initialize Terraform

```bash
terraform init
```

### 2.3 Review and Apply Infrastructure

```bash
# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

This will create:
- VPC with public and private subnets
- EKS cluster with node groups
- RDS MySQL database
- ECR repositories for Docker images
- IAM roles and policies
- Security groups

### 2.4 Get Terraform Outputs

```bash
terraform output -json > ../infrastructure-outputs.json
```

Save the outputs for later use, especially:
- `rds_endpoint` - Database endpoint
- `ecr_repository_urls` - ECR repository URLs
- `configure_kubectl` - Command to configure kubectl

## Step 3: Configure kubectl

```bash
# Configure kubectl to connect to EKS
aws eks update-kubeconfig --name bbhealthapp-cluster --region us-west-2

# Verify connection
kubectl get nodes
```

## Step 4: Build and Push Docker Images to ECR

### 4.1 Login to ECR

```bash
# Get ECR login password
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com
```

### 4.2 Build and Push Images

```bash
cd ..

# Make scripts executable (if not already)
chmod +x scripts/build-and-push-ecr.sh

# Build and push all images
./scripts/build-and-push-ecr.sh us-west-2 default
```

This will build and push:
- bbhealthapp-frontend
- bbhealthapp-master-service
- bbhealthapp-register-service
- bbhealthapp-document-service

## Step 5: Update Helm Values

### 5.1 Get Infrastructure Outputs

```bash
cd terraform
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ECR_REGISTRY=$(terraform output -raw ecr_repository_urls | jq -r 'to_entries[0].value' | cut -d'/' -f1)
cd ..
```

### 5.2 Update Helm Values

Edit `helm/bbhealthapp/values.yaml`:

```yaml
# Update image registry
image:
  registry: <YOUR_ECR_REGISTRY>  # e.g., 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Update domain name
ingress:
  hosts:
    - host: your-domain.com  # Replace with your actual domain
```

### 5.3 Create Kubernetes Secrets for Database

```bash
# Create secret for database credentials
kubectl create secret generic bbhealthapp-db-secret \
  --from-literal=db-host=<RDS_ENDPOINT> \
  --from-literal=db-username=<DB_USERNAME> \
  --from-literal=db-password=<DB_PASSWORD> \
  -n bbhealthapp
```

## Step 6: Deploy Application with Helm

### 6.1 Create Namespace

```bash
kubectl create namespace bbhealthapp
```

### 6.2 Deploy with Helm

```bash
# Add Helm chart dependencies
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy application
helm install bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --set image.registry=<YOUR_ECR_REGISTRY> \
  --set ingress.hosts[0].host=your-domain.com
```

### 6.3 Verify Deployment

```bash
# Check pods
kubectl get pods -n bbhealthapp

# Check services
kubectl get svc -n bbhealthapp

# Check ingress
kubectl get ingress -n bbhealthapp
```

## Step 7: Configure SSL/TLS (Production)

Follow the SSL/TLS configuration guide in `docs/SSL_TLS_SETUP.md` to set up HTTPS for your domain.

## Step 8: Access Your Application

### 8.1 Get Load Balancer URL

```bash
kubectl get ingress -n bbhealthapp
```

The `ADDRESS` field will show your ALB URL.

### 8.2 Update DNS

Point your domain's A record to the ALB URL.

### 8.3 Access Application

Open your browser and navigate to `https://your-domain.com`

## Step 9: Monitoring and Logging

### 9.1 View Application Logs

```bash
# Frontend logs
kubectl logs -f deployment/frontend -n bbhealthapp

# Master service logs
kubectl logs -f deployment/master-service -n bbhealthapp

# Register service logs
kubectl logs -f deployment/register-service -n bbhealthapp

# Document service logs
kubectl logs -f deployment/document-service -n bbhealthapp
```

### 9.2 CloudWatch Logs

```bash
# View EKS logs in CloudWatch
aws logs tail /aws/eks/bbhealthapp-cluster/cluster --follow --region us-west-2
```

### 9.3 RDS Monitoring

```bash
# View RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=bbhealthapp-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Step 10: Scaling

### 10.1 Horizontal Pod Autoscaler

```bash
# Enable HPA in Helm values
helm upgrade bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --set autoscaling.enabled=true
```

### 10.2 Cluster Autoscaler

Already configured in Terraform. It will automatically scale the EKS node group based on pod resource requirements.

## Step 11: Backup and Disaster Recovery

### 11.1 RDS Backups

RDS automatic backups are enabled by default (7-day retention). To increase:

```bash
# Update RDS backup retention
aws rds modify-db-instance \
  --db-instance-identifier bbhealthapp-db \
  --backup-retention-period 30 \
  --apply-immediately
```

### 11.2 EBS Snapshots

```bash
# Create EBS snapshot
aws ec2 create-snapshot \
  --volume-id <VOLUME_ID> \
  --description "BBHealthApp backup $(date)"
```

## Step 12: Cleanup (Development Only)

```bash
# Remove Helm deployment
helm uninstall bbhealthapp -n bbhealthapp

# Remove Kubernetes resources
kubectl delete namespace bbhealthapp

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <POD_NAME> -n bbhealthapp

# Check events
kubectl get events -n bbhealthapp --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Check RDS endpoint
aws rds describe-db-instances --db-instance-identifier bbhealthapp-db

# Test connectivity from pod
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -n bbhealthapp
nc -zv <RDS_ENDPOINT> 3306
```

### Image Pull Errors

```bash
# Verify ECR login
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com

# Check image exists in ECR
aws ecr describe-images --repository-name bbhealthapp-frontend --region us-west-2
```

### Ingress Not Working

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress status
kubectl describe ingress -n bbhealthapp
```

## Cost Optimization

### Development Environment

- Use `db.t3.micro` for RDS
- Use spot instances for EKS nodes
- Set backup retention to 1 day
- Disable CloudWatch logging

### Production Environment

- Use appropriate instance sizes based on load
- Enable Multi-AZ for RDS
- Use reserved instances for predictable workloads
- Enable CloudWatch logging and alerts
- Set up auto-scaling policies

## Security Best Practices

1. **Use IAM Roles**: Never use access keys in applications
2. **Enable Encryption**: Enable EBS encryption and RDS encryption
3. **Network Isolation**: Use private subnets for databases
4. **Secrets Management**: Use AWS Secrets Manager or Kubernetes Secrets
5. **Regular Updates**: Keep EKS version and AMIs updated
6. **VPC Flow Logs**: Enable VPC flow logs for network monitoring
7. **Security Groups**: Restrict security group rules to minimum required

## Support and Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions, GitLab CI, etc.)
2. Configure monitoring and alerting (Prometheus, Grafana)
3. Set up log aggregation (ELK Stack, CloudWatch Logs)
4. Implement automated testing
5. Set up disaster recovery procedures
6. Configure backup strategies
7. Implement security scanning (Trivy, Snyk)
