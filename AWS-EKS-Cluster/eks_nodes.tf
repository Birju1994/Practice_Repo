# ==============================================================================
# EKS Managed Node Group with Production Launch Template
# ==============================================================================
# Security & Stability Highlights:
# 1. Strictly bound to PRIVATE subnets: worker nodes NEVER receive public IPs.
# 2. Hardened Launch Template:
#    - IMDSv2 enforced (http_tokens = "required") to prevent SSRF credential theft.
#    - Encrypted root EBS volume (gp3) with custom disk size.
#    - Detailed monitoring enabled.
# 3. Graceful rolling upgrades configured via update_config (max_unavailable = 1).
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Custom EC2 Launch Template for Hardened Worker Nodes
# ------------------------------------------------------------------------------
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-${var.node_group_name}-lt-"
  description = "Custom launch template for hardened EKS worker nodes"

  # NOTE: Do NOT specify instance_type here. EKS Managed Node Group manages
  # instance_types directly via the node group resource (allowing multi-type lists/spot).

  # Enforce IMDSv2 (AWS Security Best Practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Prohibits insecure IMDSv1
    http_put_response_hop_limit = 2          # Allows containerized workloads with IRSA
    instance_metadata_tags      = "enabled"
  }

  # Encrypted EBS root volume with gp3 performance characteristics
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true # Detailed 1-minute CloudWatch metrics
  }

  vpc_security_group_ids = [aws_security_group.nodes.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.custom_tags,
      {
        Name                                        = "${var.cluster_name}-${var.node_group_name}-node"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.custom_tags,
      {
        Name                                        = "${var.cluster_name}-${var.node_group_name}-volume"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 2. Managed Node Group
# ------------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn

  # DEPLOY EXCLUSIVELY TO PRIVATE SUBNETS
  # Nodes communicate with AWS APIs and image registries via NAT Gateways
  subnet_ids = aws_subnet.private[*].id

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  # Zero downtime rolling upgrade configuration
  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  # Node labels for Kubernetes pod scheduling (affinity/anti-affinity/tolerations)
  labels = {
    role        = "worker"
    environment = var.environment
  }

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.cluster_name}-${var.node_group_name}"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  lifecycle {
    # Ignore desired_size changes when Cluster Autoscaler or Karpenter is actively scaling
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodes_AmazonSSMManagedInstanceCore
  ]
}
