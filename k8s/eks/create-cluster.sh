#!/bin/bash

# Script to create EKS cluster using eksctl
# Prerequisites:
# - eksctl installed
# - AWS CLI installed and configured

set -e

CLUSTER_NAME=${CLUSTER_NAME:-"bbhealthapp-cluster"}
REGION=${AWS_REGION:-"us-west-2"}
NODE_TYPE=${NODE_TYPE:-"t3.medium"}
NODES=${NODES:-"3"}
NODES_MIN=${NODES_MIN:-"2"}
NODES_MAX=${NODES_MAX:-"5"}

echo "Creating EKS cluster..."
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Node Type: $NODE_TYPE"
echo "Nodes: $NODES (min: $NODES_MIN, max: $NODES_MAX)"
echo ""

# Create cluster using eksctl
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --node-type $NODE_TYPE \
  --nodes $NODES \
  --nodes-min $NODES_MIN \
  --nodes-max $NODES_MAX \
  --with-oidc \
  --ssh-access \
  --ssh-public-key bbhealthapp-key

echo ""
echo "Cluster created successfully!"
echo ""
echo "Update kubeconfig:"
echo "  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"
echo ""
echo "Install AWS Load Balancer Controller:"
echo "  kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller"
echo ""
echo "Install ExternalDNS (optional):"
echo "  helm install external-dns bitnami/external-dns"
