#!/bin/bash

# InnovateMart EKS Deployment Script
set -e

echo "🚀 Starting InnovateMart EKS Deployment..."

# Deploy EKS Infrastructure
echo "📦 Deploying EKS infrastructure..."
cd terraform/eks/minimal
terraform init
terraform apply -auto-approve -var="environment_name=innovatemart"

# Configure kubectl
echo "⚙️ Configuring kubectl..."
KUBECTL_CMD=$(terraform output -raw configure_kubectl)
eval $KUBECTL_CMD

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy retail store application
echo "🛍️ Deploying retail store application..."
cd ../../..
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# Wait for deployments
echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment --all

# Create developer IAM user
echo "👤 Creating developer IAM user..."
aws iam create-user --user-name innovatemart-developer || true
aws iam create-access-key --user-name innovatemart-developer > developer-credentials.json || true

# Create developer policy
cat > developer-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy --policy-name innovatemart-developer-readonly --policy-document file://developer-policy.json || true
aws iam attach-user-policy --user-name innovatemart-developer --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/innovatemart-developer-readonly || true

# Create RBAC for developer
kubectl apply -f - << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-readonly
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "describe"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "describe"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-readonly-binding
subjects:
- kind: User
  name: innovatemart-developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-readonly
  apiGroup: rbac.authorization.k8s.io
EOF

# Get application URL
echo "🌐 Getting application URL..."
kubectl get svc ui

echo "✅ Deployment complete!"
echo "📋 Application URL: Check the EXTERNAL-IP from the service above"
echo "👤 Developer credentials saved to: developer-credentials.json"