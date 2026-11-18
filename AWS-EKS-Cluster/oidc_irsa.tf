# ==============================================================================
# OpenID Connect (OIDC) Identity Provider & IRSA Configuration
# ==============================================================================
# Production Security Standard:
# Instead of granting broad AWS IAM permissions to EC2 worker nodes, IAM Roles
# for Service Accounts (IRSA) allows individual Kubernetes pods to assume dedicated,
# fine-grained AWS IAM roles via standard OpenID Connect tokens.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Fetch OIDC TLS Certificate Thumbprint
# ------------------------------------------------------------------------------
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ------------------------------------------------------------------------------
# 2. Register EKS as an IAM OpenID Connect Provider
# ------------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-oidc-provider"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. Production IRSA Role Example: AWS EBS CSI Driver
# ------------------------------------------------------------------------------
# This role allows the EBS CSI Driver controller pod in kube-system to dynamically
# provision and attach EBS persistent volumes (PVs) to application pods.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver-role"
    }
  )
}

# Attach standard AWS managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}
