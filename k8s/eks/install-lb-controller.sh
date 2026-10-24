#!/bin/bash

# Script to install AWS Load Balancer Controller on EKS
# Prerequisites:
# - kubectl configured for EKS cluster
# - IAM role created (see create-iam-roles.sh)

set -e

CLUSTER_NAME=${CLUSTER_NAME:-"bbhealthapp-cluster"}
REGION=${AWS_REGION:-"us-west-2"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Installing AWS Load Balancer Controller..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""

# Apply IAM role for service account
echo "Applying IAM role for service account..."
kubectl apply -f iam-role-sa.yaml

# Add Helm repository
echo "Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller..."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$REGION \
  --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

echo ""
echo "AWS Load Balancer Controller installed successfully!"
echo ""
echo "Verify installation:"
echo "  kubectl get deployment -n kube-system aws-load-balancer-controller"
