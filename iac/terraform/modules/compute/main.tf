# =============================================================================
# Compute Module — main.tf
# =============================================================================
# All 16 EC2 instances are defined in a single map and provisioned via
# for_each. This keeps the code DRY while giving every instance its own
# specific type, disk size, subnet placement, and security group assignment.
#
# Instance Map Legend:
#   name        →  EC2 Name tag & Terraform resource key
#   type        →  EC2 instance type
#   disk        →  Root EBS volume size in GB
#   subnet      →  "public" (DMZ) or "private"
#   role        →  Ansible inventory group & tag
#   extra_sgs   →  Additional SG IDs beyond the internal-vpc default
# =============================================================================

locals {
  instances = {
    # =====================================================================
    # PUBLIC SUBNET — DMZ (Internet-facing)
    #   - load-balancer-server: Nginx reverse proxy, nhận toàn bộ traffic từ internet
    #   - teleport:            Access management (SSH/K8s proxy)
    #   - kong-gateway:        API Gateway, quản lý & route API requests
    # =====================================================================
    "load-balancer-server" = {
      type      = "t3.micro"
      disk      = 8
      subnet    = "public"
      role      = "load-balancer"
      extra_sgs = []
    }
    "teleport" = {
      type      = "t3.medium"
      disk      = 12
      subnet    = "public"
      role      = "teleport"
      extra_sgs = []
    }
    "kong-gateway" = {
      type      = "t3.medium"
      disk      = 16
      subnet    = "public"
      role      = "kong-gateway"
      extra_sgs = [var.sg_kong_id]
    }

    # =====================================================================
    # PRIVATE SUBNET — Platform Tools (internal services)
    #   - gitlab-server:     Source code management + CI/CD pipelines
    #   - harbor-server:     Docker/OCI container image registry
    #   - sonarqube-server:  Code quality & security analysis
    #   - rancher-server:    Kubernetes cluster management UI
    #   - dev-server:        CI/CD runner + developer jumpbox
    #   - elk:               Elasticsearch + Logstash + Kibana (logging stack)
    # =====================================================================
    "gitlab-server" = {
      type      = "t3.large"
      disk      = 16
      subnet    = "private"
      role      = "gitlab"
      extra_sgs = []
    }
    "harbor-server" = {
      type      = "t3.medium"
      disk      = 12
      subnet    = "private"
      role      = "harbor"
      extra_sgs = []
    }
    "sonarqube-server" = {
      type      = "t3.medium"
      disk      = 12
      subnet    = "private"
      role      = "sonarqube"
      extra_sgs = []
    }
    "rancher-server" = {
      type      = "t3.large"
      disk      = 30
      subnet    = "private"
      role      = "rancher"
      extra_sgs = []
    }
    "dev-server" = {
      type      = "t3.large"
      disk      = 18
      subnet    = "private"
      role      = "cicd-runner"
      extra_sgs = []
    }
    "elk" = {
      type      = "t3.large"
      disk      = 30
      subnet    = "private"
      role      = "elk"
      extra_sgs = [var.sg_elk_id]
    }

    # =====================================================================
    # PRIVATE SUBNET — Kubernetes HA Control-Plane (v1.30)
    #   - k8s-master-1,2,3:  etcd + kube-apiserver + controller-manager + scheduler
    # =====================================================================
    "k8s-master-1" = {
      type      = "t3.medium"
      disk      = 20
      subnet    = "private"
      role      = "k8s-master"
      extra_sgs = [var.sg_k8s_masters_id]
    }
    "k8s-master-2" = {
      type      = "t3.medium"
      disk      = 20
      subnet    = "private"
      role      = "k8s-master"
      extra_sgs = [var.sg_k8s_masters_id]
    }
    "k8s-master-3" = {
      type      = "t3.medium"
      disk      = 20
      subnet    = "private"
      role      = "k8s-master"
      extra_sgs = [var.sg_k8s_masters_id]
    }

    # =====================================================================
    # PRIVATE SUBNET — Storage HA Cluster (GlusterFS replicated)
    #   - storage-master-1,2,3:  GlusterFS bricks + NFS VIP failover
    # =====================================================================
    "storage-master-1" = {
      type      = "t3.micro"
      disk      = 8
      subnet    = "private"
      role      = "storage-node"
      extra_sgs = []
    }
    "storage-master-2" = {
      type      = "t3.micro"
      disk      = 8
      subnet    = "private"
      role      = "storage-node"
      extra_sgs = []
    }
    "storage-master-3" = {
      type      = "t3.micro"
      disk      = 8
      subnet    = "private"
      role      = "storage-node"
      extra_sgs = []
    }
  }
}

# -----------------------------------------------------------------------------
# EC2 Instances — provisioned via for_each over the map above
# -----------------------------------------------------------------------------
resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = var.ami_id
  instance_type               = each.value.type
  key_name                    = var.ssh_key_name
  subnet_id                   = each.value.subnet == "public" ? var.public_subnet_id : var.private_subnet_id
  associate_public_ip_address = each.value.subnet == "public"

  # Construct SG list: always include internal, optionally add role-specific SGs
  vpc_security_group_ids = concat(
    [var.sg_internal_id],
    each.value.role == "load-balancer" ? [var.sg_lb_id] : [],
    each.value.role == "teleport" ? [var.sg_teleport_id] : [],
    each.value.role == "kong-gateway" ? [var.sg_kong_id] : [],
    each.value.extra_sgs,
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = each.value.disk
    encrypted   = true

    tags = {
      Name        = "${var.project_name}-${each.key}-root"
      Environment = var.environment
    }
  }

  # Prevent accidental destruction of stateful nodes
  lifecycle {
    ignore_changes = [ami] # AMI updates are managed separately
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
    Role        = each.value.role
    AnsibleGroup = each.value.role
  }

  # Wait for cloud-init to finish so Ansible can run immediately
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -q
    apt-get install -y -q python3 python3-apt haveged
    # Ensure hostname is set consistently
    hostnamectl set-hostname ${each.key}
    # Disable automatic upgrades during provisioning windows
    systemctl stop unattended-upgrades.service || true
  EOF
}

# -----------------------------------------------------------------------------
# Elastic IP for the load-balancer-server
# -----------------------------------------------------------------------------
resource "aws_eip" "lb" {
  instance = aws_instance.this["load-balancer-server"].id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-lb-eip"
    Environment = var.environment
    Role        = "load-balancer"
  }

  depends_on = [aws_instance.this]
}

# -----------------------------------------------------------------------------
# Elastic IP for the Kong API Gateway (public-facing API endpoint)
# -----------------------------------------------------------------------------
resource "aws_eip" "kong" {
  instance = aws_instance.this["kong-gateway"].id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-kong-eip"
    Environment = var.environment
    Role        = "kong-gateway"
  }

  depends_on = [aws_instance.this]
}
