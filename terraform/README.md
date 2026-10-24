# BBHealthApp EKS Deployment with Terraform

This directory contains Terraform configurations for deploying the BBHealthApp to Amazon EKS.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform installed (>= 1.0)
- kubectl installed
- Docker installed
- Helm installed

## Architecture

The Terraform configuration creates:

- **VPC**: Custom VPC with public and private subnets
- **EKS Cluster**: Kubernetes control plane managed by AWS
- **Node Groups**: EKS managed node groups with auto-scaling
- **IAM Roles**: Service account IAM roles (IRSA) for AWS integration
- **Load Balancer Controller**: AWS Load Balancer Controller for ALB
- **EBS CSI Driver**: EBS CSI driver for persistent storage
- **CloudWatch Logging**: Centralized logging for EKS
- **Cluster Autoscaler**: Automatic cluster scaling

## Files

| File | Description |
|------|-------------|
| `provider.tf` | AWS and Kubernetes provider configuration |
| `variables.tf` | Variable definitions |
| `main.tf` | Main Terraform configuration |
| `vpc.tf` | VPC and networking configuration |
| `eks.tf` | EKS cluster and node groups |
| `iam.tf` | IAM roles and policies |
| `outputs.tf` | Output definitions |
| `deploy.sh` | Deployment script |

## Quick Start

### 1. Configure Environment Variables

```bash
export CLUSTER_NAME="bbhealthapp-cluster"
export AWS_REGION="us-west-2"
export ENVIRONMENT="dev"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan \
  -var="cluster_name=$CLUSTER_NAME" \
  -var="environment=$ENVIRONMENT" \
  -var="aws_region=$AWS_REGION"
```

### 4. Apply the Deployment

```bash
terraform apply \
  -var="cluster_name=$CLUSTER_NAME" \
  -var="environment=$ENVIRONMENT" \
  -var="aws_region=$AWS_REGION"
```

### 5. Configure kubectl

```bash
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
```

### 6. Deploy Application

```bash
chmod +x deploy.sh
./deploy.sh
```

## Configuration

### Variables

Key variables in `variables.tf`:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `environment` | Environment name | `dev` |
| `cluster_name` | EKS cluster name | `bbhealthapp-cluster` |
| `cluster_version` | Kubernetes version | `1.28` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `node_instance_type` | EC2 instance type | `t3.medium` |
| `node_desired_size` | Desired number of nodes | `3` |
| `node_min_size` | Minimum number of nodes | `2` |
| `node_max_size` | Maximum number of nodes | `5` |
| `enable_spot_instances` | Enable spot instances | `false` |
| `enable_cluster_autoscaler` | Enable cluster autoscaler | `true` |
| `enable_cloudwatch_logging` | Enable CloudWatch logging | `true` |

### Custom Configuration

Create a `terraform.tfvars` file to override defaults:

```hcl
aws_region              = "us-west-2"
environment             = "prod"
cluster_name            = "bbhealthapp-prod"
node_instance_type      = "t3.large"
node_desired_size       = 5
node_min_size           = 3
node_max_size           = 10
enable_spot_instances   = true
```

## Terraform State

The configuration uses S3 backend for state management:

```hcl
backend "s3" {
  bucket         = "bbhealthapp-terraform-state"
  key            = "eks/terraform.tfstate"
  region         = "us-west-2"
  encrypt        = true
  dynamodb_table = "bbhealthapp-terraform-locks"
}
```

The S3 bucket and DynamoDB table are created automatically on first apply.

## Outputs

After deployment, view the outputs:

```bash
terraform output
```

Key outputs:
- `cluster_id` - EKS cluster ID
- `cluster_endpoint` - EKS cluster endpoint
- `cluster_name` - EKS cluster name
- `vpc_id` - VPC ID
- `configure_kubectl` - Command to configure kubectl

## Accessing the Application

After deployment, get the Load Balancer URL:

```bash
kubectl get ingress -n bbhealthapp
```

Or get the Load Balancer DNS:

```bash
kubectl get svc -n bbhealthapp
```

## Scaling

### Horizontal Pod Autoscaler

Enable HPA for services:

```bash
kubectl autoscale deployment master-service \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n bbhealthapp
```

### Cluster Autoscaler

Cluster autoscaler is enabled by default. Configure in `variables.tf`:

```hcl
enable_cluster_autoscaler = true
node_min_size = 2
node_max_size = 10
```

## Monitoring

### CloudWatch

CloudWatch logging is enabled by default. View logs:

```bash
aws logs tail /aws/eks/bbhealthapp-cluster/cluster --follow --region us-west-2
```

### Prometheus + Grafana

Install Prometheus and Grafana:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

## Cost Optimization

### Spot Instances

Enable spot instances for cost savings:

```hcl
enable_spot_instances = true
```

### Right-Sizing

Monitor node utilization:

```bash
kubectl top nodes
```

## Security

### Network Policies

Enable network policies:

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Pod Security Standards

Enable Pod Security Standards:

```bash
kubectl label ns bbhealthapp pod-security.kubernetes.io/enforce=restricted
```

### Secrets Management

Use AWS Secrets Manager or Parameter Store:

```bash
# Install AWS Secrets and Configuration Provider
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

## Troubleshooting

### Terraform State Issues

If Terraform state is locked:

```bash
terraform force-unlock bbhealthapp-terraform-locks
```

### Cluster Not Ready

Check cluster status:

```bash
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION
```

### Node Issues

Check node status:

```bash
kubectl get nodes
kubectl describe node <node-name>
```

### IAM Role Issues

Verify IAM roles:

```bash
aws iam get-role --role-name AmazonEKSLoadBalancerControllerRole
aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole
```

## Cleanup

### Remove Application

```bash
cd ../k8s
kubectl delete -f ingress.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f document-service-deployment.yaml
kubectl delete -f register-service-deployment.yaml
kubectl delete -f master-service-deployment.yaml
kubectl delete -f pvc.yaml
kubectl delete -f secret.yaml
kubectl delete -f configmap.yaml
kubectl delete -f namespace.yaml
```

### Remove ECR Repositories

```bash
aws ecr delete-repository --repository-name bbhealthapp-master-service --force --region $AWS_REGION
aws ecr delete-repository --repository-name bbhealthapp-register-service --force --region $AWS_REGION
aws ecr delete-repository --repository-name bbhealthapp-document-service --force --region $AWS_REGION
aws ecr delete-repository --repository-name bbhealthapp-frontend --force --region $AWS_REGION
```

### Destroy Terraform Resources

```bash
cd ../terraform
terraform destroy \
  -var="cluster_name=$CLUSTER_NAME" \
  -var="environment=$ENVIRONMENT" \
  -var="aws_region=$AWS_REGION"
```

## Production Checklist

- [ ] Enable SSL/TLS with ACM certificate
- [ ] Configure DNS with Route 53
- [ ] Enable CloudWatch Container Insights
- [ ] Set up alarms in CloudWatch
- [ ] Configure backup strategy
- [ ] Enable cluster autoscaler
- [ ] Configure HPA for services
- [ ] Enable network policies
- [ ] Use AWS Secrets Manager for secrets
- [ ] Configure WAF for security
- [ ] Enable GuardDuty for threat detection
- [ ] Configure VPC Flow Logs
- [ ] Set up disaster recovery plan
- [ ] Configure cost monitoring
- [ ] Enable spot instances for non-critical workloads
- [ ] Configure reserved instances for production
- [ ] Enable AWS Config for compliance
- [ ] Configure AWS CloudTrail for auditing

## Multi-Environment Deployment

### Directory Structure

```
terraform/
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── terraform.tfvars
│   └── prod/
│       └── terraform.tfvars
├── main.tf
├── variables.tf
└── ...
```

### Deploy to Specific Environment

```bash
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## CI/CD Integration

### GitHub Actions

Example workflow:

```yaml
name: Deploy to EKS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Terraform Init
        run: terraform init
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## Support

For issues or questions:
- Check Terraform logs
- Review EKS cluster health
- Check AWS service health dashboard
- Review AWS documentation: https://docs.aws.amazon.com/eks/
- Review Terraform documentation: https://www.terraform.io/docs/providers/aws/
