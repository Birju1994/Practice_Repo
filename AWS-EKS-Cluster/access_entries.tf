# ==============================================================================
# Modern EKS Authentication & RBAC (EKS Access Entries API)
# ==============================================================================
# Authentication Overview:
# Starting with EKS 1.29+, AWS introduced "EKS Access Entries", deprecating the
# traditional and error-prone "aws-auth" ConfigMap.
#
# Access Entries allow managing IAM authentication and Kubernetes RBAC directly
# via AWS APIs without touching ConfigMaps or waiting for cluster readiness.
#
# Supported AWS Managed Access Policies:
# - AmazonEKSClusterAdminPolicy (Full cluster admin)
# - AmazonEKSAdminPolicy        (Admin over specific namespaces)
# - AmazonEKSEditPolicy         (Read/write access to resources)
# - AmazonEKSViewPolicy         (Read-only inspection access)
# ==============================================================================

# ==============================================================================
# Modern EKS Authentication & RBAC (EKS Access Entries API)
# ==============================================================================
# Authentication Overview:
# Starting with EKS 1.29+, AWS introduced "EKS Access Entries", deprecating the
# traditional and error-prone "aws-auth" ConfigMap.
#
# NOTE on Cluster Creator / Deployer:
# In eks_cluster.tf, "bootstrap_cluster_creator_admin_permissions = true" is set.
# This causes AWS EKS to automatically create an Admin Access Entry for the IAM
# entity running Terraform (e.g. your IAM user/role). Creating an explicit entry
# for the same principal will fail with a 409 ResourceInUseException.
#
# The resources below manage access entries for ADDITIONAL admin principals
# passed via "var.admin_principal_arns" (excluding caller to prevent conflicts).
# ==============================================================================

locals {
  # Exclude current caller if listed, since EKS bootstraps it automatically
  filtered_admin_arns = [
    for arn in var.admin_principal_arns : arn
    if arn != data.aws_caller_identity.current.arn
  ]
}

# ------------------------------------------------------------------------------
# Access Entries for Additional Admin IAM Principals (Configured via Variable)
# ------------------------------------------------------------------------------
resource "aws_eks_access_entry" "admins" {
  for_each      = toset(local.filtered_admin_arns)
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = merge(
    var.custom_tags,
    {
      Role = "ClusterAdmin"
    }
  )
}

resource "aws_eks_access_policy_association" "admins" {
  for_each      = toset(local.filtered_admin_arns)
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.admins[each.key].principal_arn

  access_scope {
    type = "cluster"
  }
}
