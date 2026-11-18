# ==============================================================================
# IAM Role & Policies for EKS Managed Worker Nodes
# ==============================================================================
# In production, EC2 worker nodes require specific AWS IAM policies to join the
# cluster, pull container images, assign secondary ENI IPs, and provide secure
# shell access via AWS Systems Manager.
# ==============================================================================

# Assume role policy document for EC2 instances
data "aws_iam_policy_document" "nodes_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for Managed Node Groups
resource "aws_iam_role" "nodes" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume_role.json

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-node-role"
    }
  )
}

# Policy 1: AmazonEKSWorkerNodePolicy
# Allows worker nodes to connect to the EKS cluster
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# Policy 2: AmazonEKS_CNI_Policy
# Allows the VPC CNI plugin to allocate secondary private IP addresses to pods
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# Policy 3: AmazonEC2ContainerRegistryReadOnly
# Allows nodes to pull private images from Amazon ECR
resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# Policy 4: AmazonSSMManagedInstanceCore (Production Best Practice)
# Allows secure console/terminal access to worker nodes residing in private subnets
# using AWS Systems Manager Session Manager, without opening SSH port 22 or deploying
# expensive/insecure bastion hosts.
resource "aws_iam_role_policy_attachment" "nodes_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}
