#!/bin/bash

# Script to pull Docker images from AWS ECR
# Usage: ./pull-from-ecr.sh [region] [profile]

set -e

# Configuration
AWS_REGION=${1:-us-west-2}
AWS_PROFILE=${2:-default}
PROJECT_NAME="bbhealthapp"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Services to pull
SERVICES=("frontend" "master-service" "register-service" "document-service")

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_REGISTRY

# Pull each service
for SERVICE in "${SERVICES[@]}"; do
    REPO_NAME="${PROJECT_NAME}-${SERVICE}"
    REPO_URI="${ECR_REGISTRY}/${REPO_NAME}"
    
    echo "Pulling ${SERVICE}..."
    docker pull $REPO_URI:latest
    echo "✓ ${SERVICE} pulled successfully"
done

echo "=========================================="
echo "All images pulled successfully!"
echo "=========================================="
