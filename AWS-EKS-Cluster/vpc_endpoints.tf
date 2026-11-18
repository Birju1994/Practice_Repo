# ==============================================================================
# AWS VPC Endpoints (AWS PrivateLink) for Maximum Security
# ==============================================================================
# Security Rationale:
# In high-security production environments (Banking, Healthcare, Defense),
# worker nodes and pods residing in private subnets should NEVER need to traverse
# the public internet or NAT Gateways to reach AWS Services (ECR, S3, STS, CloudWatch, SSM).
#
# AWS PrivateLink provisions private Elastic Network Interfaces (ENIs) inside your
# private subnets, keeping all AWS API traffic strictly on the Amazon private backbone.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Security Group for Interface VPC Endpoints
# ------------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name        = "${var.cluster_name}-vpc-endpoints-sg"
  description = "Security group for AWS PrivateLink VPC Endpoints"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound HTTPS from within VPC CIDR (nodes and pods)
  ingress {
    description = "Allow HTTPS from VPC workloads to AWS VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound from endpoint ENIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-vpc-endpoints-sg"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. S3 Gateway Endpoint (Free & Essential for ECR Docker Layer Pulls)
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.eks_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-s3-gw-endpoint"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. AWS Interface Endpoints (PrivateLink)
# ------------------------------------------------------------------------------
locals {
  interface_endpoints = var.enable_vpc_endpoints ? {
    ecr_api = {
      name = "com.amazonaws.${var.aws_region}.ecr.api"
    }
    ecr_dkr = {
      name = "com.amazonaws.${var.aws_region}.ecr.dkr"
    }
    sts = {
      name = "com.amazonaws.${var.aws_region}.sts"
    }
    logs = {
      name = "com.amazonaws.${var.aws_region}.logs"
    }
    ssm = {
      name = "com.amazonaws.${var.aws_region}.ssm"
    }
    ssmmessages = {
      name = "com.amazonaws.${var.aws_region}.ssmmessages"
    }
    ec2messages = {
      name = "com.amazonaws.${var.aws_region}.ec2messages"
    }
  } : {}
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-${each.key}-endpoint"
    }
  )
}
