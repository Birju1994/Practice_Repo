# ==============================================================================
# Managed AWS EKS Add-ons
# ==============================================================================
# In production, AWS managed add-ons are preferred over manual Helm installs
# for critical cluster infrastructure. They are auto-updated and maintained by AWS.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Amazon VPC CNI
# ------------------------------------------------------------------------------
# Assigns native VPC IP addresses to Kubernetes pods
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    var.custom_tags,
    {
      "eks_addon" = "vpc-cni"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. Kube-Proxy
# ------------------------------------------------------------------------------
# Maintains network rules on nodes to allow network communication to your pods
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    var.custom_tags,
    {
      "eks_addon" = "kube-proxy"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. CoreDNS
# ------------------------------------------------------------------------------
# Serves as the internal Kubernetes cluster DNS server.
# Note: CoreDNS pods require worker nodes to schedule onto.
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = merge(
    var.custom_tags,
    {
      "eks_addon" = "coredns"
    }
  )
}

# ------------------------------------------------------------------------------
# 4. AWS EBS CSI Driver (With IRSA Service Account Authentication)
# ------------------------------------------------------------------------------
# Manages the lifecycle of Amazon EBS volumes for PersistentVolumes
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]

  tags = merge(
    var.custom_tags,
    {
      "eks_addon" = "aws-ebs-csi-driver"
    }
  )
}
