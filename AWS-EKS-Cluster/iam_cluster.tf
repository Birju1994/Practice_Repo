# ==============================================================================
# IAM Role & Policies for EKS Cluster Control Plane
# ==============================================================================
# The EKS service needs permissions to manage AWS resources (like cross-account
# Elastic Network Interfaces and load balancers) on your behalf.
# ==============================================================================

# Assume role policy document for the EKS service
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for EKS Control Plane
resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-cluster-role"
    }
  )
}

# Policy 1: AmazonEKSClusterPolicy
# Grants permissions for the control plane to manage cluster compute and networking
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Policy 2: AmazonEKSVPCResourceController
# Enables security group policies for pods (ENI allocation per pod)
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}
