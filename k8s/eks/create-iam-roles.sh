#!/bin/bash

# Script to create IAM roles for EKS
# Prerequisites:
# - AWS CLI installed and configured
# - eksctl installed

set -e

CLUSTER_NAME=${CLUSTER_NAME:-"bbhealthapp-cluster"}
REGION=${AWS_REGION:-"us-west-2"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating IAM roles for EKS..."
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"
echo ""

# Create IAM role for AWS Load Balancer Controller
echo "Creating IAM role for AWS Load Balancer Controller..."
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

# Get OIDC provider ID
OIDC_PROVIDER_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --query "cluster.identity.oidc.issuer" \
  --output text | cut -d '/' -f 5)

echo "OIDC Provider ID: $OIDC_PROVIDER_ID"

# Create IAM role for Load Balancer Controller
aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://lb-controller-trust-policy.json \
  --region $REGION || echo "Role already exists"

# Attach policy to the role
aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/elasticloadbalancing:FullAccess \
  --region $REGION || echo "Policy already attached"

aws iam attach-role-policy \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --policy-arn arn:aws:iam::aws:policy/iam:PassRole \
  --region $REGION || echo "Policy already attached"

# Create IAM role for EBS CSI Driver
echo "Creating IAM role for EBS CSI Driver..."
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
  --assume-role-policy-document file://ebs-csi-trust-policy.json \
  --region $REGION || echo "Role already exists"

# Attach policy to the role
aws iam attach-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --region $REGION || echo "Policy already attached"

# Update the iam-role-sa.yaml file with the correct account ID
sed -i.bak "s/ACCOUNT_ID/${ACCOUNT_ID}/g" iam-role-sa.yaml
rm iam-role-sa.yaml.bak

echo ""
echo "IAM roles created successfully!"
echo ""
echo "Load Balancer Controller Role: AmazonEKSLoadBalancerControllerRole"
echo "EBS CSI Driver Role: AmazonEKS_EBS_CSI_DriverRole"
echo ""
echo "Clean up temporary files..."
rm lb-controller-trust-policy.json ebs-csi-trust-policy.json
