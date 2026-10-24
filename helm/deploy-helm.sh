#!/bin/bash

# Script to deploy BBHealthApp using Helm
# Prerequisites:
# - kubectl installed and configured
# - Helm installed
# - Docker installed

set -e

# Configuration
CHART_NAME="bbhealthapp"
NAMESPACE=${NAMESPACE:-"bbhealthapp"}
RELEASE_NAME=${RELEASE_NAME:-"bbhealthapp"}
IMAGE_REGISTRY=${IMAGE_REGISTRY:-"windsurf-project-3"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
VALUES_FILE=${VALUES_FILE:-"helm/${CHART_NAME}/values.yaml"}

echo "Deploying BBHealthApp using Helm..."
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Image Registry: $IMAGE_REGISTRY"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Build and push Docker images (if needed)
if [ "$BUILD_IMAGES" = "true" ]; then
    echo "Building Docker images..."
    cd bbhealthapp-backend/bbhealthapp-api-master
    docker build -t ${IMAGE_REGISTRY}/master-service:${IMAGE_TAG} .
    docker tag ${IMAGE_REGISTRY}/master-service:${IMAGE_TAG} ${IMAGE_REGISTRY}/master-service:latest
    cd ../..
    
    cd bbhealthapp-backend/bbhealthapp-api-register
    docker build -t ${IMAGE_REGISTRY}/register-service:${IMAGE_TAG} .
    docker tag ${IMAGE_REGISTRY}/register-service:${IMAGE_TAG} ${IMAGE_REGISTRY}/register-service:latest
    cd ../..
    
    cd bbhealthapp-backend/bbhealthapp-api-document
    docker build -t ${IMAGE_REGISTRY}/document-service:${IMAGE_TAG} .
    docker tag ${IMAGE_REGISTRY}/document-service:${IMAGE_TAG} ${IMAGE_REGISTRY}/document-service:latest
    cd ../..
    
    cd bbhealthapp-frontend
    docker build -t ${IMAGE_REGISTRY}/frontend:${IMAGE_TAG} .
    docker tag ${IMAGE_REGISTRY}/frontend:${IMAGE_TAG} ${IMAGE_REGISTRY}/frontend:latest
    cd ..
    
    echo "Docker images built successfully"
fi

# Create namespace if it doesn't exist
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository (if needed)
# helm repo add stable https://charts.helm.sh/stable
# helm repo update

# Install or upgrade Helm release
echo "Installing/upgrading Helm release..."
helm upgrade --install $RELEASE_NAME \
    helm/$CHART_NAME \
    --namespace $NAMESPACE \
    --create-namespace \
    --set image.registry=$IMAGE_REGISTRY \
    --set image.tag=$IMAGE_TAG \
    --values $VALUES_FILE \
    --wait \
    --timeout 10m

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo ""
echo "Check deployment status:"
echo "  helm status $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "Check pods:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "Check services:"
echo "  kubectl get svc -n $NAMESPACE"
echo ""
echo "Check ingress:"
echo "  kubectl get ingress -n $NAMESPACE"
echo ""
echo "Get Helm values:"
echo "  helm get values $RELEASE_NAME -n $NAMESPACE"
