# ==============================================================================
# AWS EKS Cluster (Control Plane) Configuration
# ==============================================================================
# Production Best Practices implemented:
# 1. Private API endpoint enabled for secure worker node & intra-VPC communication.
# 2. Envelope encryption of Kubernetes Secrets via dedicated AWS KMS CMK.
# 3. All 5 control plane log types forwarded to CloudWatch for compliance & auditing.
# 4. Modern EKS Access Management (API_AND_CONFIG_MAP) for streamlined IAM RBAC.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CloudWatch Log Group for Control Plane Audit & Diagnostic Logs
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-cloudwatch-logs"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. EKS Cluster Resource
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  # Networking Configuration
  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []
  }

  # Control Plane Audit and System Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Hardware-backed Envelope Encryption for Kubernetes Secrets
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
    resources = ["secrets"]
  }

  # Modern Authentication & Access Configuration (EKS Access Entries API)
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensure IAM attachments and CloudWatch Log Group exist before cluster creation
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = merge(
    var.custom_tags,
    {
      Name = var.cluster_name
    }
  )
}
