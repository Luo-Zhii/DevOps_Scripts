# =============================================================================
# Compute Module — variables.tf
# =============================================================================

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for all EC2 instances (Ubuntu 22.04 LTS)"
  type        = string
}

variable "ssh_key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  sensitive   = true
}

variable "public_subnet_id" {
  description = "Subnet ID for public-facing instances (LB, Teleport)"
  type        = string
}

variable "private_subnet_id" {
  description = "Subnet ID for all internal instances"
  type        = string
}

# -----------------------------------------------------------------------------
# Security Group IDs — passed from the security module
# -----------------------------------------------------------------------------
variable "sg_lb_id" {
  description = "SG ID for the load balancer"
  type        = string
}

variable "sg_teleport_id" {
  description = "SG ID for Teleport"
  type        = string
}

variable "sg_k8s_masters_id" {
  description = "SG ID for K8s control-plane nodes"
  type        = string
}

variable "sg_internal_id" {
  description = "SG ID for intra-VPC communication (applied to all private nodes)"
  type        = string
}

variable "sg_kong_id" {
  description = "SG ID for Kong API Gateway"
  type        = string
}

variable "sg_elk_id" {
  description = "SG ID for ELK Stack"
  type        = string
}

