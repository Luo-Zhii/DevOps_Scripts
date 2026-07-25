# =============================================================================
# Root Main — assemble modules
# =============================================================================
# The root module orchestrates three child modules:
#   1. network  — VPC, subnets, gateways, route tables
#   2. security — Security groups
#   3. compute  — EC2 instances, EIPs
#
# Module outputs are wired together so the compute module receives subnet IDs
# and SG IDs automatically.
# =============================================================================

# -----------------------------------------------------------------------------
# Network: VPC + Subnets + Gateways
# -----------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  environment         = var.environment
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

# -----------------------------------------------------------------------------
# Security: Security Groups
# -----------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
}

# -----------------------------------------------------------------------------
# Compute: EC2 instances + Elastic IP
# -----------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  environment       = var.environment
  project_name      = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  ssh_key_name      = var.ssh_key_name
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  sg_lb_id          = module.security.sg_lb_id
  sg_teleport_id    = module.security.sg_teleport_id
  sg_k8s_masters_id = module.security.sg_k8s_masters_id
  sg_k8s_workers_id = module.security.sg_k8s_workers_id
  sg_kong_id        = module.security.sg_kong_id
  sg_elk_id         = module.security.sg_elk_id
  sg_internal_id    = module.security.sg_internal_id
}
