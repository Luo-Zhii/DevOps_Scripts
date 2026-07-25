# =============================================================================
# Root Outputs — outputs.tf
# =============================================================================
# These are designed to feed directly into an Ansible inventory file.
# Use the templatefile() function or a local_file resource to write the
# inventory to disk automatically after `terraform apply`.
# =============================================================================

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.network.private_subnet_id
}

# -----------------------------------------------------------------------------
# Public Endpoints — DNS records cần trỏ vào các IP này
# -----------------------------------------------------------------------------
output "load_balancer_public_ip" {
  description = "Public IP của Nginx load balancer — trỏ DNS A record của các service domain vào đây"
  value       = module.compute.lb_public_ip
}

output "teleport_public_ip" {
  description = "Public IP của Teleport node — trỏ teleport.luo.io.vn vào đây"
  value       = module.compute.teleport_public_ip
}

output "kong_gateway_public_ip" {
  description = "Public IP của Kong API Gateway — trỏ api.luo.io.vn vào đây"
  value       = module.compute.kong_public_ip
}

output "elk_private_ip" {
  description = "Private IP của ELK node (truy cập nội bộ qua VPN/Teleport)"
  value       = module.compute.elk_private_ip
}

# -----------------------------------------------------------------------------
# Ansible Inventory — grouped by role
# -----------------------------------------------------------------------------

output "ansible_inventory_load_balancers" {
  description = "Load balancer private IP for Ansible [load_balancers] group"
  value = {
    "load-balancer-server" = {
      ansible_host = module.compute.lb_private_ip
      public_ip    = module.compute.lb_public_ip
    }
  }
}

output "ansible_inventory_teleport" {
  description = "Teleport IP for Ansible [teleport] group"
  value = {
    "teleport" = {
      ansible_host = module.compute.teleport_private_ip
      public_ip    = module.compute.teleport_public_ip
    }
  }
}

output "ansible_inventory_kong" {
  description = "Kong Gateway IP for Ansible [kong_gateway] group"
  value = {
    "kong-gateway" = {
      ansible_host = module.compute.kong_private_ip
      public_ip    = module.compute.kong_public_ip
    }
  }
}

output "ansible_inventory_elk" {
  description = "ELK private IP for Ansible [elk] group"
  value = {
    "elk" = {
      ansible_host = module.compute.elk_private_ip
    }
  }
}

output "ansible_inventory_k8s_masters" {
  description = "K8s masters for Ansible [k8s_masters] group"
  value       = module.compute.k8s_masters
}

output "ansible_inventory_storage_nodes" {
  description = "Storage nodes for Ansible [storage_nodes] group"
  value       = module.compute.storage_nodes
}

output "ansible_inventory_platform_tools" {
  description = "Platform tools for Ansible [platform_tools] group"
  value       = module.compute.platform_tools
}

# -----------------------------------------------------------------------------
# Flat map — all nodes with their private IPs
# -----------------------------------------------------------------------------
output "ansible_inventory_flat" {
  description = "Flat map of all instance names → private IPs (for ansible inventory generation)"
  value       = module.compute.all_private_ips
}
