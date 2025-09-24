# Developer IAM User for read-only EKS access
resource "aws_iam_user" "developer" {
  name = "${var.environment_name}-developer"
  
  tags = {
    Environment = var.environment_name
    Role        = "Developer"
    Project     = "Bedrock"
  }
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# Read-only policy for EKS cluster access
resource "aws_iam_policy" "developer_eks_readonly" {
  name        = "${var.environment_name}-developer-eks-readonly"
  description = "Read-only access to EKS cluster for developers"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_eks_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.developer_eks_readonly.arn
}