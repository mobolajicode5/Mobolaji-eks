#!/bin/bash

# Force cleanup script for Project Bedrock
set -e

VPC_ID="vpc-0af59270053cd4078"
REGION="eu-west-1"

echo "🧹 Starting force cleanup of AWS resources..."

# 1. Delete Kubernetes resources
echo "1. Deleting Kubernetes resources..."
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml --validate=false || true
kubectl delete svc --all --all-namespaces || true
kubectl delete pvc --all --all-namespaces || true

# 2. Delete LoadBalancers
echo "2. Deleting LoadBalancers..."
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text | xargs -I {} aws elbv2 delete-load-balancer --load-balancer-arn {} --region $REGION || true
aws elb describe-load-balancers --region $REGION --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text | xargs -I {} aws elb delete-load-balancer --load-balancer-name {} --region $REGION || true

# 3. Delete Network Interfaces
echo "3. Deleting Network Interfaces..."
aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text | xargs -I {} aws ec2 delete-network-interface --network-interface-id {} --region $REGION || true

# 4. Release Elastic IPs
echo "4. Releasing Elastic IPs..."
aws ec2 describe-addresses --region $REGION --query 'Addresses[?Domain==`vpc`].AllocationId' --output text | xargs -I {} aws ec2 release-address --allocation-id {} --region $REGION || true

# 5. Delete Security Groups (except default)
echo "5. Deleting Security Groups..."
aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | xargs -I {} aws ec2 delete-security-group --group-id {} --region $REGION || true

# 6. Wait for cleanup
echo "6. Waiting for cleanup to complete..."
sleep 120

# 7. Run Terraform destroy
echo "7. Running Terraform destroy..."
cd terraform/eks/minimal
terraform init
terraform destroy -auto-approve -var="environment_name=innovatemart"

# 8. Clean up S3 and DynamoDB
echo "8. Cleaning up S3 bucket and DynamoDB table..."
aws s3api delete-objects --bucket innovatemart-terraform-state --delete "$(aws s3api list-object-versions --bucket innovatemart-terraform-state --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" || true
aws s3api delete-objects --bucket innovatemart-terraform-state --delete "$(aws s3api list-object-versions --bucket innovatemart-terraform-state --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" || true
aws s3 rb s3://innovatemart-terraform-state --force || true
aws dynamodb delete-table --table-name terraform-state-lock --region $REGION || true

echo "✅ Force cleanup completed!"