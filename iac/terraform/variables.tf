# =============================================================================
# Root-Level Variables
# =============================================================================
# These variables drive every module. Sensible defaults are provided, but
# override them in terraform.tfvars or via -var flags for your environment.
# =============================================================================

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Short project identifier used in resource naming"
  type        = string
  default     = "devops-platform"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public (DMZ) subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet hosting all internal services"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "ap-southeast-1a"
}

# -----------------------------------------------------------------------------
# Compute / SSH
# -----------------------------------------------------------------------------
variable "ssh_key_name" {
  description = "Name of an existing AWS EC2 Key Pair for SSH access"
  type        = string
  # Sensitive: this must be provided at plan/apply time
  sensitive   = true
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH into instances (for Teleport bootstrap)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Replace with your office VPN / static IP range
}

# -----------------------------------------------------------------------------
# Instance AMI — dynamically resolved from SSM, see data.tf
# -----------------------------------------------------------------------------
variable "ubuntu_ami_name_pattern" {
  description = "Name pattern for the Ubuntu 22.04 LTS AMI lookup via SSM"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}
