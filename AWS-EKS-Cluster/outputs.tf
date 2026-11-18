# ==============================================================================
# Outputs
# ==============================================================================
# Essential connection strings, ARNs, and configuration commands.
# ==============================================================================

output "cluster_name" {
  description = "Name of the created EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL for the Kubernetes API server."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes control plane version."
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS worker nodes."
  value       = aws_security_group.nodes.id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OpenID Connect (OIDC) provider for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the IAM OpenID Connect (OIDC) provider."
  value       = aws_iam_openid_connect_provider.eks.url
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for Kubernetes Secrets envelope encryption."
  value       = aws_kms_key.eks_secrets.arn
}

output "vpc_id" {
  description = "ID of the dedicated VPC."
  value       = aws_vpc.eks_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (for ALBs and NAT Gateways)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (for worker nodes with private internet access)."
  value       = aws_subnet.private[*].id
}

output "configure_kubectl_command" {
  description = "Convenient AWS CLI command to authenticate and configure local kubeconfig."
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${aws_eks_cluster.main.name}"
}

output "bastion_instance_id" {
  description = "EC2 Instance ID of the secure private SSM Bastion host."
  value       = var.enable_bastion ? aws_instance.bastion[0].id : null
}

output "bastion_ssm_connect_command" {
  description = "AWS CLI command to start an interactive terminal session on the private Bastion host without SSH."
  value       = var.enable_bastion ? "aws ssm start-session --region ${var.aws_region} --target ${aws_instance.bastion[0].id}" : null
}

output "bastion_port_forward_to_eks_api" {
  description = "AWS CLI SSM port-forwarding command to route local port 8443 to the strictly private EKS API endpoint."
  value       = var.enable_bastion ? "aws ssm start-session --region ${var.aws_region} --target ${aws_instance.bastion[0].id} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host=\"${replace(aws_eks_cluster.main.endpoint, "https://", "")}\",portNumber=\"443\",localPortNumber=\"8443\"" : null
}
