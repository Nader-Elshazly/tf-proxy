terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project_name}-${terraform.workspace}"
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = local.name_prefix
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.3.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}

module "load_balancing" {
  source          = "./modules/load_balancing"
  project_name    = local.name_prefix
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
}

module "compute" {
  source                  = "./modules/compute"
  project_name            = local.name_prefix
  vpc_id                  = module.vpc.vpc_id
  public_subnets          = module.vpc.public_subnets
  private_subnets         = module.vpc.private_subnets
  internal_tg_arn         = module.load_balancing.internal_tg_arn
  internal_alb_dns        = module.load_balancing.internal_alb_dns
  key_name                = var.key_name
  instance_count_proxies  = var.instance_count_proxies
  instance_count_backends = var.instance_count_backends
  private_key_path        = var.private_key_path
  ssh_allowed_cidr        = var.ssh_allowed_cidr
  aws_region              = var.aws_region
}

output "public_alb_dns" {
  value = module.load_balancing.public_alb_dns
}

output "internal_alb_dns" {
  value = module.load_balancing.internal_alb_dns
}
