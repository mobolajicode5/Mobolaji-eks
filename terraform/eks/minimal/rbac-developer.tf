# Kubernetes RBAC for developer read-only access
resource "kubernetes_cluster_role" "developer_readonly" {
  metadata {
    name = "developer-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "namespaces"]
    verbs      = ["get", "list", "describe"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "describe"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list"]
  }

  depends_on = [module.retail_app_eks]
}

resource "kubernetes_cluster_role_binding" "developer_readonly" {
  metadata {
    name = "developer-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.developer_readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = aws_iam_user.developer.name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [kubernetes_cluster_role.developer_readonly]
}