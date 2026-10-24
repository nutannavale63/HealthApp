#!/bin/bash

# Script to build and push Docker images to AWS ECR
# Usage: ./build-and-push-ecr.sh [region] [profile]

set -e

# Configuration
AWS_REGION=${1:-us-west-2}
AWS_PROFILE=${2:-default}
PROJECT_NAME="bbhealthapp"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Services to build
declare -A SERVICES=(
    ["frontend"]="bbhealthapp-frontend"
    ["master-service"]="bbhealthapp-backend/bbhealthapp-api-master"
    ["register-service"]="bbhealthapp-backend/bbhealthapp-api-register"
    ["document-service"]="bbhealthapp-backend/bbhealthapp-api-document"
)

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push each service
for SERVICE_KEY in "${!SERVICES[@]}"; do
    SERVICE_PATH="${SERVICES[$SERVICE_KEY]}"
    REPO_NAME="${PROJECT_NAME}-${SERVICE_KEY}"
    REPO_URI="${ECR_REGISTRY}/${REPO_NAME}"
    
    echo "=========================================="
    echo "Building ${SERVICE_KEY}..."
    echo "=========================================="
    
    # Build image
    cd $SERVICE_PATH
    docker build -t $REPO_NAME .
    docker tag $REPO_NAME $REPO_URI:latest
    docker tag $REPO_NAME $REPO_URI:$(date +%Y%m%d-%H%M%S)
    
    # Push image
    echo "Pushing ${SERVICE_KEY} to ECR..."
    docker push $REPO_URI:latest
    docker push $REPO_URI:$(date +%Y%m%d-%H%M%S)
    
    cd - > /dev/null
    echo "✓ ${SERVICE_KEY} pushed successfully"
done

echo "=========================================="
echo "All images built and pushed successfully!"
echo "=========================================="

# Output repository URLs
echo ""
echo "ECR Repository URLs:"
for SERVICE_KEY in "${!SERVICES[@]}"; do
    REPO_NAME="${PROJECT_NAME}-${SERVICE_KEY}"
    echo "  ${SERVICE_KEY}: ${ECR_REGISTRY}/${REPO_NAME}"
done
