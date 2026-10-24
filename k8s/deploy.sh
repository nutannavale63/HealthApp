#!/bin/bash

# Script to deploy BBHealthApp to Kubernetes

set -e

NAMESPACE="bbhealthapp"

echo "Deploying BBHealthApp to Kubernetes..."
echo ""

# Create namespace
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# Create ECR pull secret
echo "Creating ECR pull secret..."
kubectl create secret docker-registry ecr-pull-secret \
  --docker-server=538707363561.dkr.ecr.us-west-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-west-2) \
  --namespace=bbhealthapp --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMap and Secret
echo "Applying ConfigMap and Secret..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Apply PersistentVolumeClaims
echo "Applying PersistentVolumeClaims..."
kubectl apply -f pvc.yaml

# Deploy backend services
echo "Deploying Master Service..."
kubectl apply -f master-service-deployment.yaml

echo "Deploying Register Service..."
kubectl apply -f register-service-deployment.yaml

echo "Deploying Document Service..."
kubectl apply -f document-service-deployment.yaml

# Deploy frontend
echo "Deploying Frontend..."
kubectl apply -f frontend-deployment.yaml

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f ingress.yaml

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=master-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=register-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=document-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n $NAMESPACE --timeout=300s

echo ""
echo "All pods are ready!"
echo ""
echo "Services:"
echo "  Frontend: http://bbhealthapp.local"
echo "  Master Service: http://bbhealthapp.local/api/master"
echo "  Register Service: http://bbhealthapp.local/api/register"
echo "  Document Service: http://bbhealthapp.local/api/document"
echo ""
echo "To check pod status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/master-service -n $NAMESPACE"
echo "  kubectl logs -f deployment/register-service -n $NAMESPACE"
echo "  kubectl logs -f deployment/document-service -n $NAMESPACE"
echo "  kubectl logs -f deployment/frontend -n $NAMESPACE"
