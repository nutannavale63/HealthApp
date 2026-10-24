#!/bin/bash

# Script to build and push Docker images for Kubernetes deployment
# This script assumes you have a Docker registry configured
# Modify the REGISTRY variable to point to your registry

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
REGISTRY="538707363561.dkr.ecr.us-west-2.amazonaws.com"
PROJECT_NAME="bbhealthapp"
IMAGE_TAG=${1:-latest}

echo "Building Docker images for Kubernetes deployment..."
echo "Registry: $REGISTRY"
echo "Tag: $IMAGE_TAG"
echo ""

# Build Master Service
echo "Building Master Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-master || exit 1
docker build -t ${REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} .
docker tag ${REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG} ${REGISTRY}/${PROJECT_NAME}-master-service:latest
docker push ${REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG}
docker push ${REGISTRY}/${PROJECT_NAME}-master-service:latest
cd "${SCRIPT_DIR}"

# Build Register Service
echo "Building Register Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-register || exit 1
docker build -t ${REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} .
docker tag ${REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG} ${REGISTRY}/${PROJECT_NAME}-register-service:latest
docker push ${REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG}
docker push ${REGISTRY}/${PROJECT_NAME}-register-service:latest
cd "${SCRIPT_DIR}"

# Build Document Service
echo "Building Document Service..."
cd ../bbhealthapp-backend/bbhealthapp-api-document || exit 1
docker build -t ${REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} .
docker tag ${REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG} ${REGISTRY}/${PROJECT_NAME}-document-service:latest
docker push ${REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG}
docker push ${REGISTRY}/${PROJECT_NAME}-document-service:latest
cd "${SCRIPT_DIR}"

# Build Frontend
echo "Building Frontend..."
cd ../bbhealthapp-frontend || exit 1
docker build -t ${REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} .
docker tag ${REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG} ${REGISTRY}/${PROJECT_NAME}-frontend:latest
docker push ${REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}
docker push ${REGISTRY}/${PROJECT_NAME}-frontend:latest
cd "${SCRIPT_DIR}"

echo ""
echo "All images built and pushed successfully!"
echo ""
echo "Images:"
echo "  - ${REGISTRY}/${PROJECT_NAME}-master-service:${IMAGE_TAG}"
echo "  - ${REGISTRY}/${PROJECT_NAME}-register-service:${IMAGE_TAG}"
echo "  - ${REGISTRY}/${PROJECT_NAME}-document-service:${IMAGE_TAG}"
echo "  - ${REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}"
