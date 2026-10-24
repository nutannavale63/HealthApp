# BBHealthApp AWS CLI Deployment Guide

This guide provides instructions for deploying the BBHealthApp to AWS using only AWS CLI commands (no Terraform or CloudFormation).

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- kubectl installed
- Docker installed
- eksctl installed (for EKS cluster creation - pure AWS CLI for EKS is extremely complex)

## Architecture

The AWS CLI deployment creates:

- **VPC**: Custom VPC with public and private subnets
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet internet access
- **Route Tables**: Public and private route tables
- **EKS Cluster**: Kubernetes control plane
- **ECR**: Elastic Container Registry for Docker images
- **IAM Roles**: Service account IAM roles (IRSA)

## Deployment Steps

### 1. Configure Environment Variables

```bash
export CLUSTER_NAME="bbhealthapp-cluster"
export AWS_REGION="us-west-2"
export ENVIRONMENT="dev"
```

### 2. Run Deployment Script

```bash
cd aws-cli
chmod +x deploy-aws-cli.sh
./deploy-aws-cli.sh
```

## AWS CLI Commands Reference

### VPC Creation

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=bbhealthapp-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text \
  --region us-west-2)

# Enable DNS support
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support \
  --enable-dns-hostnames \
  --region us-west-2
```

### Internet Gateway

```bash
# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=bbhealthapp-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text \
  --region us-west-2)

# Attach to VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region us-west-2
```

### Subnets

```bash
# Create Public Subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.101.0/24 \
  --availability-zone us-west-2a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=bbhealthapp-public-subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text \
  --region us-west-2)

# Create Private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-west-2a \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=bbhealthapp-private-subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text \
  --region us-west-2)
```

### NAT Gateway

```bash
# Allocate Elastic IP
EIP_ALLOCATION_ID=$(aws ec2 allocate-address \
  --query 'AllocationId' \
  --output text \
  --region us-west-2)

# Create NAT Gateway
NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID \
  --allocation-id $EIP_ALLOCATION_ID \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=bbhealthapp-nat-gateway}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text \
  --region us-west-2)

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids $NAT_GATEWAY_ID \
  --region us-west-2
```

### Route Tables

```bash
# Create Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=bbhealthapp-public-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region us-west-2)

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region us-west-2

# Associate with public subnet
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID \
  --region us-west-2

# Create Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=bbhealthapp-private-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region us-west-2)

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GATEWAY_ID \
  --region us-west-2

# Associate with private subnet
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RT_ID \
  --subnet-id $PRIVATE_SUBNET_ID \
  --region us-west-2
```

### EKS Cluster

```bash
# Create EKS cluster using eksctl
# Note: Pure AWS CLI for EKS is extremely complex and requires CloudFormation
# eksctl is the recommended AWS CLI-based tool

eksctl create cluster \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --vpc-id $VPC_ID \
  --vpc-private-subnets $PRIVATE_SUBNET_ID \
  --vpc-public-subnets $PUBLIC_SUBNET_ID \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --with-oidc
```

### Configure kubectl

```bash
aws eks update-kubeconfig --name bbhealthapp-cluster --region us-west-2
```

### IAM Roles for Service Accounts

```bash
# Get OIDC provider ID
OIDC_PROVIDER_ID=$(aws eks describe-cluster \
  --name bbhealthapp-cluster \
  --region us-west-2 \
  --query "cluster.identity.oidc.issuer" \
  --output text | cut -d '/' -f 5)

# Create trust policy
cat > lb-controller-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_PROVIDER_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_PROVIDER_ID}:aud": "sts.amazonaws.com",
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_PROVIDER_ID}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://lb-controller-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/elasticloadbalancing:FullAccess

aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/iam:PassRole
```

### ECR Repositories

```bash
# Create ECR repository
aws ecr create-repository --repository-name bbhealthapp-master-service --region us-west-2

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push image
docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/bbhealthapp-master-service:latest .
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/bbhealthapp-master-service:latest
```

### Kubernetes Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f pvc.yaml
kubectl apply -f master-service-deployment.yaml
kubectl apply -f register-service-deployment.yaml
kubectl apply -f document-service-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
```

## Verification

### Check VPC

```bash
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region us-west-2
```

### Check Subnets

```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region us-west-2
```

### Check EKS Cluster

```bash
aws eks describe-cluster --name bbhealthapp-cluster --region us-west-2
```

### Check Pods

```bash
kubectl get pods -n bbhealthapp
```

### Check Services

```bash
kubectl get svc -n bbhealthapp
```

### Get Load Balancer URL

```bash
kubectl get ingress -n bbhealthapp
```

## Cleanup

### Delete Kubernetes Resources

```bash
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

### Delete EKS Cluster

```bash
eksctl delete cluster --name bbhealthapp-cluster --region us-west-2
```

### Delete ECR Repositories

```bash
aws ecr delete-repository --repository-name bbhealthapp-master-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-register-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-document-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-frontend --force --region us-west-2
```

### Delete VPC Resources

```bash
# Delete NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID --region us-west-2

# Release Elastic IP
aws ec2 release-address --allocation-id $EIP_ALLOCATION_ID --region us-west-2

# Detach Internet Gateway
aws ec2 detach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region us-west-2

# Delete Internet Gateway
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region us-west-2

# Delete subnets
for SUBNET_ID in "${PUBLIC_SUBNET_IDS[@]}" "${PRIVATE_SUBNET_IDS[@]}"; do
  aws ec2 delete-subnet --subnet-id $SUBNET_ID --region us-west-2
done

# Delete route tables
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID --region us-west-2
aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID --region us-west-2

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region us-west-2
```

### Delete IAM Roles

```bash
aws iam detach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/elasticloadbalancing:FullAccess

aws iam detach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/iam:PassRole

aws iam delete-role --role-name AmazonEKSLoadBalancerControllerRole
```

## Notes

### Why eksctl for EKS?

Creating an EKS cluster using pure AWS CLI is extremely complex because:
1. EKS cluster creation requires CloudFormation stack creation
2. Node group creation requires multiple API calls
3. IAM role creation and attachment is complex
4. OIDC provider configuration requires multiple steps

eksctl is built by AWS and is the recommended CLI-based tool for EKS cluster management. It uses AWS CLI under the hood but simplifies the process significantly.

### Pure AWS CLI Alternative

If you absolutely must use pure AWS CLI (no eksctl), you would need to:
1. Use CloudFormation via AWS CLI to create EKS cluster
2. Create CloudFormation templates for all resources
3. Use AWS CLI to deploy CloudFormation stacks

This is essentially the same as using Terraform but with CloudFormation instead.

### Recommended Approach

For production deployments, the recommended approaches are:
1. **Terraform** - Most popular, declarative, state management
2. **CloudFormation** - AWS-native, integrates well with AWS services
3. **eksctl** - Simple CLI-based tool for EKS
4. **AWS CLI** - Only for simple operations or when other tools aren't available

## Troubleshooting

### NAT Gateway Stuck in Pending

```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --region us-west-2

# Wait for it to become available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID --region us-west-2
```

### EKS Cluster Not Ready

```bash
# Check cluster status
aws eks describe-cluster --name bbhealthapp-cluster --region us-west-2

# Check node status
kubectl get nodes
```

### Image Pull Errors

```bash
# Verify ECR repository exists
aws ecr describe-repositories --repository-names bbhealthapp-master-service --region us-west-2

# Verify you're logged in to ECR
docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
```

## Cost Considerations

AWS CLI deployment creates the following billable resources:
- EKS Cluster: ~$0.10/hour
- EC2 Instances: ~$0.04-0.10/hour per instance (t3.medium)
- NAT Gateway: ~$0.045/hour + $0.045/GB data processing
- ECR: $0.10/GB/month
- EBS Volumes: ~$0.08-0.10/GB/month

Estimated monthly cost for dev environment: ~$150-200
Estimated monthly cost for production: ~$500-1000+

Remember to delete resources when not in use to avoid unnecessary charges.
