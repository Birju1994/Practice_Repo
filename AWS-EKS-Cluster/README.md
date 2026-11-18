# Production-Grade AWS EKS Cluster with Terraform

This repository provides an enterprise-ready, production-grade Infrastructure as Code (Terraform) blueprint to deploy a highly available **Amazon Elastic Kubernetes Service (EKS)** cluster inside **dedicated private subnets with private internet access** via AWS NAT Gateways and **strictly private API server endpoint access**.

---

## 🏛 Architecture Overview

```
                                      AWS CLOUD (VPC 10.0.0.0/16)
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │  INTERNET GATEWAY (IGW)                                                                │
 │    │                                                                                   │
 │  PUBLIC SUBNETS (Multi-AZ)                                                             │
 │  ├── Public Subnets (AZ 1a, 1b, 1c)                                                    │
 │  ├── Internet-facing Application Load Balancers (kubernetes.io/role/elb = 1)           │
 │  └── AWS Managed NAT Gateways (Multi-AZ HA egress)                                     │
 │        │                                                                               │
 │        ▼ (Outbound Egress Only: Container updates, external APIs)                      │
 │  PRIVATE SUBNETS (Worker Nodes & Workloads - Zero Direct Ingress from Internet)        │
 │  ├── EKS Worker Nodes (NO Public IPs, gp3 encrypted EBS, IMDSv2 enforced)              │
 │  ├── Internal Load Balancers (kubernetes.io/role/internal-elb = 1)                     │
 │  ├── Secure SSM Bastion Host (Zero open inbound ports, pre-loaded with kubectl)        │
 │  └── AWS PrivateLink VPC Endpoints (ECR, S3, STS, CloudWatch Logs, SSM)                │
 │        │                                                                               │
 │        ▼ (100% Private AWS API Calls via AWS Internal Backbone)                        │
 │  EKS MANAGED CONTROL PLANE                                                             │
 │  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
 │  │  • Kubernetes API Server (Strictly Private Access inside VPC - Zero Internet DNS)│  │
 │  │  • Secrets Envelope Encryption via dedicated AWS KMS Customer Managed Key (CMK) │  │
 │  │  • All 5 Audit & Control Plane Logs streamed to CloudWatch Logs                  │  │
 │  │  • Modern EKS Access Entries (IAM RBAC without aws-auth ConfigMap risks)         │  │
 │  │  • OpenID Connect (OIDC) Identity Provider for IRSA                              │  │
 │  └──────────────────────────────────────────────────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔒 Production Security & Best Practices Implemented

| Area | Production Implementation |
| :--- | :--- |
| **Worker Subnets** | Placed strictly in **private subnets** with **no public IPs**. Outbound internet access strictly via AWS NAT Gateways. |
| **Strictly Private API Endpoint** | `cluster_endpoint_public_access = false` and `cluster_endpoint_private_access = true`. The API server has **no public IP and is never exposed to the internet**. |
| **AWS PrivateLink Endpoints** | VPC Endpoints for **ECR (API & DKR), S3, STS (for IRSA), CloudWatch Logs, and SSM**. Pods communicate with AWS APIs privately within the AWS network without traversing NAT Gateways or the internet. |
| **SSM-Managed Bastion** | Secure management host in the private subnet with **zero open inbound ports** (no SSH port 22). Access and manage the private cluster via **AWS Systems Manager Session Manager**. |
| **High Availability** | Deployed across 3 Availability Zones with independent NAT Gateways (configurable for cost-saving via `single_nat_gateway`). |
| **Secrets Encryption** | Envelope encryption of all Kubernetes secrets using a dedicated **AWS KMS Customer Managed Key (CMK)** with automatic key rotation enabled. |
| **Node Hardening** | Custom Launch Template enforcing **IMDSv2** (`http_tokens = "required"`, `http_put_response_hop_limit = 2`) to protect against SSRF credential theft. Encrypted `gp3` root volumes. |
| **Authentication & RBAC** | Configured with modern **EKS Access Entries API** (`authentication_mode = "API_AND_CONFIG_MAP"`), superseding legacy `aws-auth` ConfigMap. Automatic admin access for deployer and bastion identities. |
| **Service Accounts (IRSA)** | **IAM OIDC Provider** configured to grant least-privilege IAM roles directly to Kubernetes pods (e.g. EBS CSI Driver) via Web Identity tokens instead of wide node-level IAM roles. |
| **Audit Logging** | All 5 EKS control plane log streams enabled: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler` with CloudWatch retention policies. |

---

## 📁 Repository Structure

```
Practice_Repo/AWS-EKS-Cluster/
├── versions.tf               # Terraform and provider constraint definitions
├── variables.tf              # Input variables, validation rules, and defaults
├── terraform.tfvars.example  # Sample configuration values ready for customization
├── vpc.tf                    # VPC, public/private subnets, IGW, NAT GWs, Route tables
├── vpc_endpoints.tf          # AWS PrivateLink VPC Endpoints (ECR, S3, STS, Logs, SSM)
├── bastion.tf                # SSM-managed private Bastion host (Zero inbound ports, kubectl pre-installed)
├── kms.tf                    # AWS KMS Customer Managed Key for secrets envelope encryption
├── security_groups.tf        # Cluster, Worker Node, and Bastion security groups
├── iam_cluster.tf            # IAM Role and policies for EKS Control Plane
├── iam_nodes.tf              # IAM Role and policies for Worker Nodes (including AWS SSM)
├── eks_cluster.tf            # EKS Control Plane, logging, encryption, and access config
├── eks_nodes.tf              # Managed Node Group and hardened EC2 Launch Template
├── oidc_irsa.tf              # OIDC Identity Provider & IRSA Role for EBS CSI Driver
├── eks_addons.tf             # Core AWS EKS Add-ons (vpc-cni, kube-proxy, coredns, ebs-csi)
├── access_entries.tf         # Modern EKS Access Entries (Authentication & RBAC associations)
├── outputs.tf                # Connection endpoints, ARNs, SSM connect & tunnel commands
└── README.md                 # Complete documentation and deployment guide
```

---

## 🚀 Quick Start & Deployment Guide

### 1. Prerequisites
- **Terraform** (`>= 1.5.0`)
- **AWS CLI** (`v2`) configured with appropriate IAM credentials (`aws configure`)
- **AWS Session Manager Plugin** installed on your local machine (for SSM connections)

### 2. Configure Variables
Copy `terraform.tfvars.example` to `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Initialize & Deploy
```bash
# 1. Initialize Terraform
terraform init

# 2. Plan the deployment
terraform plan -out=tfplan

# 3. Apply infrastructure
terraform apply tfplan
```

---

## 🔐 How to Access the Strictly Private Cluster API Endpoint

Because `cluster_endpoint_public_access = false`, the Kubernetes API is only reachable from within the VPC. You have two secure methods to access it:

### Method 1: Interactive Session via SSM Bastion Host (Easiest)
Directly connect to the private Bastion host inside your VPC using AWS Systems Manager:
```bash
# Run the command from terraform output
aws ssm start-session --region <your-region> --target <bastion-instance-id>
```
Once inside the bastion, update kubeconfig and run `kubectl`:
```bash
aws eks --region <your-region> update-kubeconfig --name prod-eks-cluster
kubectl get nodes -o wide
kubectl get pods -A
```

### Method 2: SSM Port-Forwarding Tunnel from Your Local Laptop
You can tunnel your local machine's port `8443` through AWS SSM directly to the private EKS API endpoint without opening any ports:
```bash
# Start the port forwarding session
aws ssm start-session --region <your-region> --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters host="<eks-cluster-endpoint-hostname>",portNumber="443",localPortNumber="8443"
```
Then configure your local `kubectl` to talk to `https://localhost:8443`!

---

## 🧹 Tear Down / Cleanup
To destroy all provisioned resources:
```bash
terraform destroy -auto-approve
```
