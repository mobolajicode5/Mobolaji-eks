# Project Bedrock - InnovateMart EKS Deployment Guide

## Architecture Overview
- **EKS Cluster**: `innovatemart` with managed node groups
- **VPC**: Custom VPC with public/private subnets across multiple AZs
- **Application**: Retail store microservices with in-cluster dependencies
- **Developer Access**: Read-only IAM user with Kubernetes RBAC

## Quick Deployment

### 1. Deploy Infrastructure
```bash
cd terraform/eks/minimal
terraform init
terraform apply -var-file="terraform.tfvars"
```

### 2. Configure kubectl
```bash
# Get the command from Terraform output
terraform output -raw configure_kubectl
# Example: aws eks --region us-west-2 update-kubeconfig --name innovatemart
```

### 3. Deploy Application
```bash
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
kubectl wait --for=condition=available --timeout=600s deployment --all
```

### 4. Access Application
```bash
kubectl get svc ui
# Use EXTERNAL-IP from LoadBalancer
```

## Developer Access Configuration

### Get Developer Credentials
```bash
cd terraform/eks/minimal
echo "Access Key: $(terraform output -raw developer_access_key_id)"
echo "Secret Key: $(terraform output -raw developer_secret_access_key)"
```

### Configure Developer AWS CLI
```bash
aws configure set aws_access_key_id <ACCESS_KEY>
aws configure set aws_secret_access_key <SECRET_KEY>
aws configure set region us-west-2
```

### Configure Developer kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name innovatemart
```

### Available Developer Commands
```bash
# View pods and services
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# Describe resources
kubectl describe pod <pod-name> -n <namespace>
kubectl describe service <service-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # Follow logs

# Check deployment status
kubectl get deployments --all-namespaces
```

## CI/CD Pipeline

### GitHub Secrets Required
- `AWS_ACCESS_KEY_ID`: AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for deployment

### Pipeline Triggers
- **Pull Request**: Runs `terraform plan` for validation
- **Push to main**: Runs `terraform apply` and deploys application

### Branching Strategy
- Feature branches → Create PR → Terraform plan runs
- Merge to main → Terraform apply + Application deployment

## Infrastructure Components

### Created Resources
- VPC with public/private subnets
- EKS cluster with managed node groups
- IAM roles and policies for EKS
- Developer IAM user with read-only access
- Kubernetes RBAC for developer access
- AWS Load Balancer Controller
- Certificate Manager

### Application Components
- UI Service (Java) - LoadBalancer
- Catalog Service (Go) - MySQL backend
- Cart Service (Java) - DynamoDB Local
- Orders Service (Java) - PostgreSQL + RabbitMQ
- Checkout Service (Node.js) - Redis

## Security Features
- Private subnets for worker nodes
- Security groups with minimal required access
- IAM roles following least privilege principle
- Kubernetes RBAC for fine-grained access control
- No hardcoded credentials in code

## Monitoring & Observability
- All services instrumented with Prometheus metrics
- OpenTelemetry OTLP tracing support
- CloudWatch integration via EKS
- Application and infrastructure logs

## Cleanup
```bash
# Remove application
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# Destroy infrastructure
cd terraform/eks/minimal
terraform destroy -var-file="terraform.tfvars"
```