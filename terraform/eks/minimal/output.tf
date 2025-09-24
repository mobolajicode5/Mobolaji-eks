output "configure_kubectl" {
  description = "Command to update kubeconfig for this cluster"
  value       = module.retail_app_eks.configure_kubectl
}

output "developer_access_key_id" {
  description = "Access key ID for developer user"
  value       = aws_iam_access_key.developer.id
}

output "developer_secret_access_key" {
  description = "Secret access key for developer user"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.environment_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.retail_app_eks.cluster_endpoint
}