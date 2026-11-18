# ==============================================================================
# AWS KMS Customer Managed Key (CMK) for Kubernetes Secrets Envelope Encryption
# ==============================================================================
# Production Best Practice (CIS Benchmark & PCI-DSS/HIPAA):
# Kubernetes secrets stored in etcd should never be left unencrypted at rest.
# Using an AWS KMS Customer Managed Key (CMK) provides hardware-backed
# envelope encryption and an audit trail in AWS CloudTrail whenever a secret is
# created, decrypted, or rotated.
# ==============================================================================

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks_secrets" {
  description             = "KMS Customer Managed Key for EKS Secrets Envelope Encryption (${var.cluster_name})"
  deletion_window_in_days = 30
  enable_key_rotation     = true # Automatically rotate key once a year

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "eks-kms-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS Service to Encrypt/Decrypt Secrets"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.cluster_name}-secrets-kms-key"
    }
  )
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/eks-${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}
