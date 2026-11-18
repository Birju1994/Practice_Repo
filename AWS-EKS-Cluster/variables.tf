# ==============================================================================
# Variables Configuration
# ==============================================================================
# Detailed input variables with descriptions, types, validation rules,
# and sensible production defaults.
# ==============================================================================

variable "aws_region" {
  description = "AWS deployment region for all infrastructure resources."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Target environment name (e.g. prod, staging, dev)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, staging, prod."
  }
}

variable "project_name" {
  description = "Project or workload identifier used in resource naming and tags."
  type        = string
  default     = "enterprise"
}

variable "cluster_name" {
  description = "Name of the AWS EKS Cluster."
  type        = string
  default     = "prod-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes control plane version. Keep updated with AWS EKS supported versions."
  type        = string
  default     = "1.30"
}

# ------------------------------------------------------------------------------
# Networking (VPC & Subnets) Variables
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the dedicated EKS VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones to distribute subnets across (min 2, ideally 3 for HA)."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 Availability Zones are required for high availability EKS control plane."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (used exclusively for ALBs and NAT Gateways)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (used for EKS Worker Nodes and internal services)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "single_nat_gateway" {
  description = "Set to true for single NAT Gateway (cost-saving in dev/stage). In production, set to false for 1 NAT Gateway per AZ (HA)."
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# EKS Cluster Endpoint Security Variables
# ------------------------------------------------------------------------------

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint access (Mandatory for production security)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint access. Set to false for strictly private access (recommended for production)."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks permitted to reach public API server endpoint when public access is enabled."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_vpc_endpoints" {
  description = "Provision AWS PrivateLink VPC Endpoints (ECR, S3, STS, CloudWatch Logs, SSM) so AWS API calls stay 100% private inside AWS backbone without internet."
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Deploy an SSM-managed secure Bastion host in the private subnet for running kubectl against the private EKS API endpoint without opening any inbound ports or SSH keys."
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the SSM Bastion management host."
  type        = string
  default     = "t3.micro"
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days for EKS control plane audit/API logs."
  type        = number
  default     = 30
}

# ------------------------------------------------------------------------------
# EKS Managed Node Group Variables
# ------------------------------------------------------------------------------

variable "node_group_name" {
  description = "Name of the managed node group."
  type        = string
  default     = "primary-apps"
}

variable "node_ami_type" {
  description = "AMI type for the EKS managed node group. EKS 1.30+ requires AL2023_x86_64_STANDARD (Amazon Linux 2 is deprecated/unsupported in 1.30)."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group. Using Free-Tier eligible t3.small for compatibility with Free-Tier accounts."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Root EBS disk size in GB for worker nodes."
  type        = number
  default     = 20
}

# ------------------------------------------------------------------------------
# Authentication & Access Entries Variables
# ------------------------------------------------------------------------------

variable "admin_principal_arns" {
  description = "List of IAM User ARNs or IAM Role ARNs to grant EKS Cluster Admin permissions via Access Entries."
  type        = list(string)
  default     = []
}

variable "custom_tags" {
  description = "Additional custom resource tags."
  type        = map(string)
  default     = {}
}
