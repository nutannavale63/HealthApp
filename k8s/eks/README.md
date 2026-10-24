# BBHealthApp EKS Deployment Guide

This guide provides step-by-step instructions for deploying the BBHealthApp to Amazon Elastic Kubernetes Service (EKS).

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- kubectl installed
- eksctl installed (for cluster creation)
- Docker installed
- Helm installed (for AWS Load Balancer Controller)

## Architecture Overview

The EKS deployment includes:

- **EKS Cluster**: Kubernetes control plane managed by AWS
- **ECR**: Elastic Container Registry for Docker images
- **ALB**: Application Load Balancer for external access
- **EBS**: Elastic Block Store for persistent storage
- **IAM Roles**: Service account IAM roles (IRSA) for AWS integration

## Deployment Steps

### Step 1: Create EKS Cluster

Using eksctl (recommended):

```bash
cd k8s/eks
chmod +x create-cluster.sh
./create-cluster.sh
```

Or manually with eksctl:

```bash
eksctl create cluster \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --with-oidc
```

Update kubeconfig:

```bash
aws eks update-kubeconfig --name bbhealthapp-cluster --region us-west-2
```

### Step 2: Create IAM Roles

Create IAM roles for service accounts:

```bash
chmod +x create-iam-roles.sh
./create-iam-roles.sh
```

This creates:
- `AmazonEKSLoadBalancerControllerRole` - For AWS Load Balancer Controller
- `AmazonEKS_EBS_CSI_DriverRole` - For EBS CSI driver

### Step 3: Install AWS Load Balancer Controller

```bash
chmod +x install-lb-controller.sh
./install-lb-controller.sh
```

### Step 4: Configure Storage

Apply EBS storage classes:

```bash
kubectl apply -f storageclass.yaml
```

### Step 5: Deploy Application

Deploy the application to EKS:

```bash
chmod +x deploy-eks.sh
./deploy-eks.sh
```

This script will:
1. Create ECR repositories
2. Build and push Docker images to ECR
3. Update deployment files with ECR registry
4. Deploy all resources to EKS
5. Wait for pods to be ready

### Step 6: Verify Deployment

Check pod status:

```bash
kubectl get pods -n bbhealthapp
```

Check services:

```bash
kubectl get svc -n bbhealthapp
```

Get the Load Balancer URL:

```bash
kubectl get ingress -n bbhealthapp
```

Or get the Load Balancer DNS:

```bash
kubectl get svc -n bbhealthapp
```

## Configuration

### Environment Variables

Set these environment variables before deployment:

```bash
export CLUSTER_NAME="bbhealthapp-cluster"
export AWS_REGION="us-west-2"
export AWS_ACCOUNT_ID="your-account-id"
```

### Image Tag

To deploy a specific image version:

```bash
./deploy-eks.sh v1.0.0
```

### Node Configuration

Modify cluster creation parameters in `create-cluster.sh`:

- `NODE_TYPE`: EC2 instance type (default: t3.medium)
- `NODES`: Number of nodes (default: 3)
- `NODES_MIN`: Minimum nodes for auto-scaling (default: 2)
- `NODES_MAX`: Maximum nodes for auto-scaling (default: 5)

## Accessing the Application

Once deployed, access the application using the Load Balancer URL:

```bash
# Get the Load Balancer URL
kubectl get ingress bbhealthapp-ingress -n bbhealthapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Or check the AWS Console:
1. Go to EC2 Load Balancers
2. Find the load balancer created by the ingress
3. Copy the DNS name
4. Access via browser: `http://<load-balancer-dns>`

## SSL/TLS Configuration

For production, enable SSL/TLS:

### 1. Create ACM Certificate

```bash
aws acm request-certificate \
  --domain-name bbhealthapp.example.com \
  --validation-method DNS \
  --region us-east-1  # ACM certificates must be in us-east-1 for ALB
```

### 2. Validate Certificate

Follow the DNS validation steps in the AWS Console.

### 3. Update Ingress

Uncomment and update the SSL annotations in `ingress-eks.yaml`:

```yaml
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:account:certificate/xxxxxx
alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
alb.ingress.kubernetes.io/ssl-redirect: "443"
```

### 4. Apply Updated Ingress

```bash
kubectl apply -f ingress-eks.yaml
```

## Scaling

### Horizontal Pod Autoscaler

Enable HPA for services:

```bash
# Master Service
kubectl autoscale deployment master-service \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n bbhealthapp

# Frontend
kubectl autoscale deployment frontend \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n bbhealthapp
```

### Cluster Autoscaler

Enable cluster autoscaler in eksctl cluster config or add to existing cluster:

```bash
eksctl utils enable-cluster-autoscaler \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --nodes-min=2 \
  --nodes-max=10
```

## Monitoring

### CloudWatch

EKS integrates with CloudWatch for monitoring:

```bash
# Enable CloudWatch Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml
```

### Prometheus + Grafana

Install Prometheus and Grafana:

```bash
# Add Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

## Logging

### CloudWatch Logs

Enable CloudWatch logging for EKS:

```bash
# Create CloudWatch log group
aws logs create-log-group --log-group-name /aws/eks/bbhealthapp-cluster/containers

# Update cluster to enable logging
eksctl utils update-cluster-logging \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --enable-types all \
  --approve
```

## Backup and Disaster Recovery

### EBS Snapshots

Automate EBS snapshot creation:

```bash
# List volumes
aws ec2 describe-volumes --filters Name=tag:kubernetes.io/created-for/pvc/name,Values=master-data-pvc

# Create snapshot
aws ec2 create-snapshot --volume-id <volume-id> --description "Master data backup"
```

### EBS Lifecycle Manager

Configure EBS Lifecycle Manager in AWS Console for automated snapshots.

## Cost Optimization

### Right-Sizing Nodes

Monitor node utilization and adjust node types:

```bash
kubectl top nodes
```

### Spot Instances

Use spot instances for cost savings:

```bash
eksctl create cluster \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --node-type t3.medium \
  --nodes 3 \
  --spot
```

### Reserved Instances

Purchase reserved instances for production workloads.

## Security

### Network Policies

Enable network policies:

```bash
# Install Calico
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

### VPC Configuration

Ensure proper VPC configuration:
- Private subnets for worker nodes
- Public subnets for load balancers
- Security groups with proper rules
- Network ACLs for additional security

## Troubleshooting

### Pods Not Starting

```bash
kubectl describe pod <pod-name> -n bbhealthapp
kubectl logs <pod-name> -n bbhealthapp
```

### Load Balancer Issues

```bash
# Check ingress
kubectl describe ingress bbhealthapp-ingress -n bbhealthapp

# Check AWS Load Balancer Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### EBS Volume Issues

```bash
# Check PVC
kubectl describe pvc <pvc-name> -n bbhealthapp

# Check EBS CSI driver
kubectl logs -n kube-system daemonset/ebs-csi-node
```

### Image Pull Errors

Ensure ECR repositories exist and images are pushed:

```bash
aws ecr describe-repositories --repository-names bbhealthapp-master-service
```

### IAM Role Issues

Verify IAM roles are correctly attached:

```bash
aws iam get-role --role-name AmazonEKSLoadBalancerControllerRole
```

## Cleanup

### Remove Application

```bash
kubectl delete -f ingress-eks.yaml
kubectl delete -f ../frontend-deployment.yaml
kubectl delete -f ../document-service-deployment.yaml
kubectl delete -f ../register-service-deployment.yaml
kubectl delete -f ../master-service-deployment.yaml
kubectl delete -f pvc-eks.yaml
kubectl delete -f ../secret.yaml
kubectl delete -f ../configmap.yaml
kubectl delete -f ../namespace.yaml
```

### Remove ECR Repositories

```bash
aws ecr delete-repository --repository-name bbhealthapp-master-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-register-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-document-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-frontend --force --region us-west-2
```

### Remove IAM Roles

```bash
aws iam delete-role --role-name AmazonEKSLoadBalancerControllerRole
aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole
```

### Delete Cluster

```bash
eksctl delete cluster --name bbhealthapp-cluster --region us-west-2
```

## Terraform Alternative

For infrastructure as code, use Terraform. See `terraform/` directory for Terraform configurations.

## Production Checklist

- [ ] Enable SSL/TLS with ACM certificate
- [ ] Configure DNS with Route 53
- [ ] Enable CloudWatch Container Insights
- [ ] Set up alarms in CloudWatch
- [ ] Configure backup strategy
- [ ] Enable cluster autoscaling
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

## Support

For issues or questions:
- Check CloudWatch logs
- Review EKS cluster health
- Check AWS service health dashboard
- Review AWS documentation: https://docs.aws.amazon.com/eks/
