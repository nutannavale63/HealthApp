#!/bin/bash

# Script to deploy BBHealthApp to AWS EKS
# Prerequisites:
# - AWS CLI installed and configured
# - kubectl installed
# - eksctl installed (optional, for cluster creation)
# - Docker installed

set -e

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"bbhealthapp-cluster"}
REGION=${AWS_REGION:-"us-west-2"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PROJECT_NAME="bbhealthapp"
IMAGE_TAG=${1:-latest}

echo "Deploying BBHealthApp to EKS..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

# Check if cluster exists
if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
    echo "Cluster $CLUSTER_NAME already exists"
    echo "Updating kubeconfig..."
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
else
    echo "Cluster $CLUSTER_NAME does not exist"
    echo "Please create the cluster first using eksctl or AWS console"
    echo "Example with eksctl:"
    echo "eksctl create cluster --name $CLUSTER_NAME --region $REGION --nodes 3"
    exit 1
fi

# Create ECR repositories if they don't exist
echo "Creating ECR repositories..."
for service in master-service register-service document-service frontend; do
    REPO_NAME="${PROJECT_NAME}-${service}"
    if aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION &>/dev/null; then
        echo "Repository $REPO_NAME already exists"
    else
        echo "Creating repository $REPO_NAME..."
        aws ecr create-repository --repository-name $REPO_NAME --region $REGION
    fi
done

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push images
echo "Building and pushing Docker images..."

# Master Service
echo "Building Master Service..."
cd ../../bbhealthapp-backend/bbhealthapp-api-master
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-master-service:latest
cd ../../../k8s

# Register Service
echo "Building Register Service..."
cd ../../bbhealthapp-backend/bbhealthapp-api-register
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-register-service:latest
cd ../../../k8s

# Document Service
echo "Building Document Service..."
cd ../../bbhealthapp-backend/bbhealthapp-api-document
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-document-service:latest
cd ../../../k8s

# Frontend
echo "Building Frontend..."
cd ../../bbhealthapp-frontend
docker build -t ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} .
docker tag ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}
docker push ${ECR_REGISTRY}/${PROJECT_NAME}-frontend:latest
cd ../k8s

# Update deployment files with ECR registry
echo "Updating deployment files with ECR registry..."
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" master-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" register-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" document-service-deployment.yaml
sed -i.bak "s|image: windsurf-project-3-|image: ${ECR_REGISTRY}/${PROJECT_NAME}-|g" frontend-deployment.yaml

# Deploy to EKS
echo "Deploying to EKS..."
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
echo "Restoring original deployment files..."
mv master-service-deployment.yaml.bak master-service-deployment.yaml
mv register-service-deployment.yaml.bak register-service-deployment.yaml
mv document-service-deployment.yaml.bak document-service-deployment.yaml
mv frontend-deployment.yaml.bak frontend-deployment.yaml

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=master-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=register-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=document-service -n bbhealthapp --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n bbhealthapp --timeout=300s

echo ""
echo "All pods are ready!"
echo ""
echo "Get the load balancer URL:"
echo "  kubectl get ingress -n bbhealthapp"
echo ""
echo "Or get the load balancer DNS:"
echo "  kubectl get svc -n bbhealthapp"
