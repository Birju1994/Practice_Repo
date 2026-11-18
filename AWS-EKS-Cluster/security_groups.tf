# ==============================================================================
# Security Groups (Least Privilege Architecture)
# ==============================================================================
# EKS requires strict network boundaries between:
# 1. Cluster Control Plane Security Group (managed ENIs created by AWS)
# 2. Worker Node Security Group (EC2 worker instances in private subnets)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Cluster Control Plane Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS control plane ENIs"
  vpc_id      = aws_vpc.eks_vpc.id

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.cluster_name}-cluster-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. Worker Node Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for all worker nodes in the cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. Security Group Rules - Cluster Control Plane
# ------------------------------------------------------------------------------

# Allow worker nodes to communicate with the EKS API server (port 443)
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods and kubelets on nodes to communicate with cluster API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
}

# Allow private API server access from within VPC (for Bastion, VPN, internal CI/CD runners)
resource "aws_security_group_rule" "cluster_ingress_vpc_https" {
  description       = "Allow HTTPS access to private API server endpoint from within VPC"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = [var.vpc_cidr]
}

# Allow cluster control plane outbound traffic to worker nodes on kubelet (10250) and webhooks (443)
resource "aws_security_group_rule" "cluster_egress_node" {
  description              = "Allow control plane to reach worker nodes for kubelet exec, logs, and proxy"
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "cluster_egress_node_https" {
  description              = "Allow control plane to reach extension API servers and admission webhooks on nodes"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
}

# ------------------------------------------------------------------------------
# 4. Security Group Rules - Worker Nodes
# ------------------------------------------------------------------------------

# Intra-node communication: Allow pods on different nodes to communicate freely
resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow all inter-node and inter-pod network communication"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
}

# Allow control plane to communicate with kubelet (port 10250) for kubectl exec, logs, port-forward
resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  description              = "Allow control plane to manage kubelet service on worker nodes"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
}

# Allow control plane to communicate with pods running admission webhooks (port 443)
resource "aws_security_group_rule" "node_ingress_cluster_https" {
  description              = "Allow control plane to communicate with admission webhooks on nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
}

# Outbound Egress: Allow worker nodes to reach the internet via NAT Gateway (for image registry, updates, APIs)
resource "aws_security_group_rule" "node_egress_internet" {
  description       = "Allow worker nodes outbound internet access through NAT Gateway"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
}
