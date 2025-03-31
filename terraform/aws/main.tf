# ============================
# AWS MAIN.TF (Refactored to Use variables.tf)
# ============================

provider "aws" {
  region = var.aws_region
}

# --- VPC for Application Workloads ---
module "aws_network" {
  source              = "terraform-aws-modules/vpc/aws"
  name                = var.vpc_name
  cidr                = var.vpc_cidr
  azs                 = var.availability_zones
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                = var.default_tags
}

# --- EKS Cluster ---
module "aws_eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = module.aws_network.vpc_id
  subnets         = module.aws_network.private_subnets
  enable_irsa     = true

  eks_managed_node_groups = {
    default_node_group = {
      instance_types   = var.eks_node_instance_types
      desired_capacity = var.eks_node_desired_capacity
      max_capacity     = var.eks_node_max_capacity
      min_capacity     = var.eks_node_min_capacity
    }
  }

  tags = var.default_tags
}

# --- ECR Repositories ---
resource "aws_ecr_repository" "java_backend" {
  name = var.ecr_java_name
  tags = var.default_tags
}

resource "aws_ecr_repository" "python_service" {
  name = var.ecr_python_name
  tags = var.default_tags
}

resource "aws_ecr_repository" "node_service" {
  name = var.ecr_node_name
  tags = var.default_tags
}

# --- Outputs ---
output "aws_vpc_id" {
  value = module.aws_network.vpc_id
}

output "aws_eks_cluster_name" {
  value = module.aws_eks.cluster_name
}

output "aws_eks_cluster_endpoint" {
  value = module.aws_eks.cluster_endpoint
}

output "aws_public_subnets" {
  value = module.aws_network.public_subnets
}

output "aws_private_subnets" {
  value = module.aws_network.private_subnets
}