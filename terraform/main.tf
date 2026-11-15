
# ==============================================================
# Jerney EKS Cluster - Managed Node Group
# ==============================================================

# ---- Availability Zones ----

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }

  filter {
    name   = "zone-id"
    values = ["aps1-az1", "aps1-az3", "aps1-az2"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}


# ==============================================================
# VPC
# ==============================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  # Three private subnets
  private_subnets = [
    for k, v in local.azs :
    cidrsubnet(var.vpc_cidr, 4, k)
  ]

  # Three public subnets
  public_subnets = [
    for k, v in local.azs :
    cidrsubnet(var.vpc_cidr, 8, k + 48)
  ]

  # NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  # Public subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Private subnet tags
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


# ==============================================================
# EKS CLUSTER - WITHOUT AUTO MODE
# ==============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS API access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Authentication
  authentication_mode = "API"

  enable_cluster_creator_admin_permissions = true

  # Enable IAM Roles for Service Accounts
  enable_irsa = true

  # Encryption
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  # Control plane logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Kubernetes add-ons
  # AWS manages these add-ons.
  bootstrap_self_managed_addons = false

  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent    = true
      before_compute = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }
  }


  # ============================================================
  # EKS MANAGED NODE GROUP
  # ============================================================

  eks_managed_node_groups = {

    workers = {

      name = "${var.cluster_name}-workers"

      # EC2 configuration
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      # Node scaling limits
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Kubernetes node labels
      labels = {
        role        = "worker"
        environment = "dev"
      }

    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
