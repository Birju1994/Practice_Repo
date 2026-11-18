# ==============================================================================
# Production VPC Architecture
# ==============================================================================
# In production, worker nodes must live in PRIVATE subnets without public IPs.
# Outbound traffic (container image pulls, package updates, external APIs) is
# routed strictly through managed AWS NAT Gateways.
#
# Kubernetes Subnet Tags:
# - "kubernetes.io/role/elb = 1" on Public Subnets tells AWS Load Balancer
#   Controller to provision internet-facing ALBs/NLBs here.
# - "kubernetes.io/role/internal-elb = 1" on Private Subnets tells AWS Load
#   Balancer Controller to provision internal ALBs/NLBs here.
# - "kubernetes.io/cluster/<cluster-name> = shared" ensures EKS services discover
#   the subnets.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. VPC Definition
# ------------------------------------------------------------------------------
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.environment}-${var.project_name}-vpc"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# ------------------------------------------------------------------------------
# 2. Internet Gateway (Public Egress & Ingress for Load Balancers)
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-${var.project_name}-igw"
    }
  )
}

# ------------------------------------------------------------------------------
# 3. Public Subnets (For NAT Gateways & External Load Balancers)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Required only for ALB/NAT Gateway interfaces

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.environment}-public-subnet-${var.availability_zones[count.index]}"
      "kubernetes.io/role/elb"                    = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# ------------------------------------------------------------------------------
# 4. Private Subnets (For EKS Worker Nodes & Application Workloads)
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # CRITICAL: No public IPs for worker nodes

  tags = merge(
    var.custom_tags,
    {
      Name                                        = "${var.environment}-private-subnet-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb"           = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# ------------------------------------------------------------------------------
# 5. Elastic IPs for NAT Gateways
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------------------------------
# 6. NAT Gateways (Provides Private Subnets with Outbound Internet Access)
# ------------------------------------------------------------------------------
resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-nat-gw-${var.availability_zones[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------------------------------
# 7. Public Route Table & Associations
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# 8. Private Route Tables & Associations (Routed via NAT Gateways)
# ------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-private-rt-${var.availability_zones[count.index]}"
    }
  )
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
