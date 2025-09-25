#!/bin/bash

# Complete deployment script for Project Bedrock
set -e

echo "🚀 Starting Project Bedrock deployment..."

# 1. Create S3 bucket and DynamoDB table
echo "1. Creating S3 bucket and DynamoDB table..."
aws s3 mb s3://innovatemart-terraform-state --region eu-west-1 || true
aws s3api put-bucket-versioning --bucket innovatemart-terraform-state --versioning-configuration Status=Enabled || true
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region eu-west-1 || true

# 2. Deploy infrastructure
echo "2. Deploying EKS infrastructure..."
cd terraform/eks/minimal
terraform init
terraform apply -auto-approve -var="environment_name=innovatemart"

# 3. Configure kubectl
echo "3. Configuring kubectl..."
KUBECTL_CMD=$(terraform output -raw configure_kubectl)
eval $KUBECTL_CMD

# 4. Deploy application
echo "4. Deploying retail store application..."
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml --validate=false
kubectl wait --for=condition=available --timeout=600s deployment --all

# 5. Get application URL
echo "5. Getting application URL..."
kubectl get svc ui

# 6. Display developer credentials
echo "6. Developer credentials:"
echo "Access Key: $(terraform output -raw developer_access_key_id)"
echo "Secret Key: $(terraform output -raw developer_secret_access_key)"
echo "Cluster: $(terraform output -raw cluster_name)"
echo "Region: eu-west-1"

echo "✅ Project Bedrock deployment completed!"
echo "🌐 Access your retail store using the LoadBalancer URL above"