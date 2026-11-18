# ==============================================================================
# Secure Bastion / Jump Host (SSM Managed, Zero Open Inbound Ports)
# ==============================================================================
# Purpose:
# When the EKS cluster API endpoint is set to strictly private
# (cluster_endpoint_public_access = false), this bastion host resides inside the
# private subnet to provide secure kubectl access via AWS Systems Manager (SSM).
#
# Key Security Properties:
# - ZERO inbound security group rules (No SSH port 22 open).
# - ZERO public IP address assigned (operates inside the private subnet).
# - Session authentication via IAM & AWS Systems Manager Session Manager.
# - Pre-installs kubectl, AWS CLI, and Helm.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Fetch Latest Amazon Linux 2023 AMI
# ------------------------------------------------------------------------------
data "aws_ami" "al2023" {
  count       = var.enable_bastion ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ------------------------------------------------------------------------------
# 2. Bastion IAM Role & Policies
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "bastion_assume_role" {
  count = var.enable_bastion ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "bastion" {
  count              = var.enable_bastion ? 1 : 0
  name               = "${var.cluster_name}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role[0].json

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-bastion-role"
    }
  )
}

# Attach SSM policy so instances register with Session Manager
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.enable_bastion ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion[0].name
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.enable_bastion ? 1 : 0
  name  = "${var.cluster_name}-bastion-profile"
  role  = aws_iam_role.bastion[0].name
}

# ------------------------------------------------------------------------------
# 3. Bastion Security Group (Zero Inbound Rules!)
# ------------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for SSM Bastion with zero open inbound ports"
  vpc_id      = aws_vpc.eks_vpc.id

  # ZERO ingress rules: SSM connections are initiated outbound via TLS to AWS SSM endpoints

  egress {
    description = "Allow all outbound traffic for package installs and EKS API calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-bastion-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 4. Bastion EC2 Instance (Placed in Private Subnet)
# ------------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  ami                  = data.aws_ami.al2023[0].id
  instance_type        = var.bastion_instance_type
  subnet_id            = aws_subnet.private[0].id # Private subnet
  iam_instance_profile = aws_iam_instance_profile.bastion[0].name
  vpc_security_group_ids = [
    aws_security_group.bastion[0].id
  ]

  # Enforce IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y git curl jq tar
              
              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              # Configure default environment for ec2-user
              echo "alias k=kubectl" >> /home/ec2-user/.bashrc
              echo "complete -o default -F __start_kubectl k" >> /home/ec2-user/.bashrc
              EOF

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-secure-bastion"
    }
  )
}

# ------------------------------------------------------------------------------
# 5. Access Entry for Bastion IAM Role
# ------------------------------------------------------------------------------
# Grants the Bastion instance cluster admin access to interact with the private EKS cluster
resource "aws_eks_access_entry" "bastion" {
  count         = var.enable_bastion ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.bastion[0].arn
  type          = "STANDARD"
  user_name     = "bastion-admin"
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  count         = var.enable_bastion ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.bastion[0].principal_arn

  access_scope {
    type = "cluster"
  }
}
