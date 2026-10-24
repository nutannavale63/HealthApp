#!/bin/bash

# Script to deploy BBHealthApp to EKS using only AWS CLI commands
# Prerequisites:
# - AWS CLI installed and configured
# - kubectl installed
# - Docker installed
# - eksctl installed (for some EKS operations that are complex with pure CLI)

set -e

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"bbhealthapp-cluster"}
REGION=${AWS_REGION:-"us-west-2"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
PROJECT_NAME="bbhealthapp"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_TAG=${1:-latest}

# VPC Configuration
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDRS=("10.0.101.0/24" "10.0.102.0/24" "10.0.103.0/24")
PRIVATE_SUBNET_CIDRS=("10.0.1.0/24" "10.0.2.0/24" "10.0.3.0/24")
AVAILABILITY_ZONES=("us-west-2a" "us-west-2b" "us-west-2c")

echo "Deploying BBHealthApp to EKS using AWS CLI..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"
echo "Account: $ACCOUNT_ID"
echo ""

# Step 1: Create VPC
echo "Step 1: Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'Vpc.VpcId' \
  --output text \
  --region $REGION)

echo "VPC created: $VPC_ID"

# Enable DNS support
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support \
  --enable-dns-hostnames \
  --region $REGION

# Step 2: Create Internet Gateway
echo "Step 2: Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text \
  --region $REGION)

aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION

echo "Internet Gateway created: $IGW_ID"

# Step 3: Create Public Subnets
echo "Step 3: Creating Public Subnets..."
PUBLIC_SUBNET_IDS=()
for i in "${!PUBLIC_SUBNET_CIDRS[@]}"; do
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block ${PUBLIC_SUBNET_CIDRS[$i]} \
    --availability-zone ${AVAILABILITY_ZONES[$i]} \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-subnet-$i},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=kubernetes.io/role/elb,Value=1},{Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)
  
  PUBLIC_SUBNET_IDS+=($SUBNET_ID)
  echo "Public Subnet $i created: $SUBNET_ID"
done

# Step 4: Create Private Subnets
echo "Step 4: Creating Private Subnets..."
PRIVATE_SUBNET_IDS=()
for i in "${!PRIVATE_SUBNET_CIDRS[@]}"; do
  SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block ${PRIVATE_SUBNET_CIDRS[$i]} \
    --availability-zone ${AVAILABILITY_ZONES[$i]} \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-subnet-$i},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}},{Key=kubernetes.io/role/internal-elb,Value=1},{Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $REGION)
  
  PRIVATE_SUBNET_IDS+=($SUBNET_ID)
  echo "Private Subnet $i created: $SUBNET_ID"
done

# Step 5: Create NAT Gateway
echo "Step 5: Creating NAT Gateway..."
EIP_ALLOCATION_ID=$(aws ec2 allocate-address \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${PROJECT_NAME}-nat-eip},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'AllocationId' \
  --output text \
  --region $REGION)

NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
  --subnet-id ${PUBLIC_SUBNET_IDS[0]} \
  --allocation-id $EIP_ALLOCATION_ID \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-nat-gateway},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text \
  --region $REGION)

echo "NAT Gateway created: $NAT_GATEWAY_ID"
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids $NAT_GATEWAY_ID \
  --region $REGION

# Step 6: Create Route Tables
echo "Step 6: Creating Route Tables..."

# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-rt},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region $REGION)

aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION

# Associate public subnets with public route table
for SUBNET_ID in "${PUBLIC_SUBNET_IDS[@]}"; do
  aws ec2 associate-route-table \
    --route-table-id $PUBLIC_RT_ID \
    --subnet-id $SUBNET_ID \
    --region $REGION
done

# Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-rt},{Key=Project,Value=${PROJECT_NAME}},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region $REGION)

aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GATEWAY_ID \
  --region $REGION

# Associate private subnets with private route table
for SUBNET_ID in "${PRIVATE_SUBNET_IDS[@]}"; do
  aws ec2 associate-route-table \
    --route-table-id $PRIVATE_RT_ID \
    --subnet-id $SUBNET_ID \
    --region $REGION
done

echo "Route tables created and configured"

# Step 7: Create EKS Cluster
echo "Step 7: Creating EKS Cluster..."
# Note: EKS cluster creation with pure AWS CLI is complex
# We'll use eksctl for this part as it's the recommended approach
# If you strictly need AWS CLI only, you would need to use boto3 or CloudFormation

echo "Creating EKS cluster using eksctl (recommended approach)..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --vpc-id $VPC_ID \
  --vpc-private-subnets $(IFS=,; echo "${PRIVATE_SUBNET_IDS[*]}") \
  --vpc-public-subnets $(IFS=,; echo "${PUBLIC_SUBNET_IDS[*]}") \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --with-oidc

echo "EKS cluster created"

# Step 8: Configure kubectl
echo "Step 8: Configuring kubectl..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Step 9: Create IAM Roles for Service Accounts
echo "Step 9: Creating IAM Roles for Service Accounts..."

# Get OIDC provider ID
OIDC_PROVIDER_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --query "cluster.identity.oidc.issuer" \
  --output text | cut -d '/' -f 5)

echo "OIDC Provider ID: $OIDC_PROVIDER_ID"

# Create IAM role for Load Balancer Controller
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

aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-policy-document file://lb-controller-trust-policy.json \
  --region $REGION || echo "Role already exists"

aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/elasticloadbalancing:FullAccess \
  --region $REGION || echo "Policy already attached"

aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/iam:PassRole \
  --region $REGION || echo "Policy already attached"

# Create IAM role for EBS CSI Driver
cat > ebs-csi-trust-policy.json <<EOF
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
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_PROVIDER_ID}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-policy-document file://ebs-csi-trust-policy.json \
  --region $REGION || echo "Role already exists"

aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region $REGION || echo "Policy already attached"

echo "IAM roles created"

# Step 10: Create ECR Repositories
echo "Step 10: Creating ECR Repositories..."
for service in master-service register-service document-service frontend; do
    REPO_NAME="${PROJECT_NAME}-${service}"
    if aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION &>/dev/null; then
        echo "Repository $REPO_NAME already exists"
    else
        echo "Creating repository $REPO_NAME..."
        aws ecr create-repository --repository-name $REPO_NAME --region $REGION
    fi
done

# Step 11: Build and Push Docker Images
echo "Step 11: Building and Pushing Docker Images..."

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Master Service
echo "Building Master Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-master
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:latest
cd ../../../aws-cli

# Register Service
echo "Building Register Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-register
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:latest
cd ../../../aws-cli

# Document Service
echo "Building Document Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-document
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:latest
cd ../../../aws-cli

# Frontend
echo "Building Frontend..."
cd ../bbhealthapp-frontend
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest
cd ../aws-cli

# Step 12: Deploy Kubernetes Resources
echo "Step 12: Deploying Kubernetes Resources..."
cd ../k8s

# Update deployment files with ECR registry
echo "Updating deployment files with ECR registry..."
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" master-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" register-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" document-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" frontend-deployment.yaml

# Use EKS-specific ingress
cp eks/ingress-eks.yaml ingress.yaml

# Use EKS-specific PVC
cp eks/pvc-eks.yaml pvc.yaml

# Apply Kubernetes resources
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f pvc.yaml
kubectl apply -f master-service-deployment.yaml
kubectl apply -f register-service-deployment.yaml
kubectl apply -f document-service-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Restore original deployment files
mv master-service-deployment.yaml.bak master-service-deployment.yaml
mv register-service-deployment.yaml.bak register-service-deployment.yaml
mv document-service-deployment.yaml.bak document-service-deployment.yaml
mv frontend-deployment.yaml.bak frontend-deployment.yaml

cd ../aws-cli

# Clean up temporary files
rm lb-controller-trust-policy.json ebs-csi-trust-policy.json

echo ""
echo "Deployment completed successfully!"
echo ""
echo "VPC ID: $VPC_ID"
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=master-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=register-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=document-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n bbhealthapp --timeout=300s

echo ""
echo "All pods are ready!"
echo ""
echo "Get the Load Balancer URL:"
echo "  kubectl get ingress -n bbhealthapp"
echo ""
echo "Or get the Load Balancer DNS:"
echo "  kubectl get svc -n bbhealthapp"
