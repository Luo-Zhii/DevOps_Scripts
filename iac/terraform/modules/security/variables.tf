# =============================================================================
# Security Module — variables.tf
# =============================================================================

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID that these security groups belong to"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used to allow all intra-VPC traffic"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH to Teleport / bootstrap"
  type        = list(string)
}
