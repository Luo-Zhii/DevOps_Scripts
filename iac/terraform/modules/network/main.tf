# =============================================================================
# Network Module — main.tf
# =============================================================================
# Provisions a custom VPC with one public and one private subnet, an Internet
# Gateway for outbound traffic, and a NAT Gateway so private instances can
# reach the internet (e.g. for apt updates) without being directly reachable.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Required for Rancher & internal service FQDNs

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway — attached to the public subnet's route table
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Elastic IP for the NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway — placed in the *public* subnet so private instances can egress
# -----------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Public Subnet (DMZ) — hosts LB, Teleport
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Instances in this subnet get a public IP

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Tier        = "public"
  }
}

# -----------------------------------------------------------------------------
# Private Subnet — hosts all platform, K8s, and storage nodes
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Tier        = "private"
  }
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------
# Public RT — routes 0.0.0.0/0 through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Private RT — routes 0.0.0.0/0 through the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route Table <-> Subnet Associations
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
