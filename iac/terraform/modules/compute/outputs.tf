# =============================================================================
# Compute Module — outputs.tf
# =============================================================================
# These outputs feed into the root outputs.tf, which in turn generates the
# Ansible inventory. Each output exposes the private IP (and public IP where
# applicable) so the inventory is always up-to-date.
# =============================================================================

# -----------------------------------------------------------------------------
# DMZ — Public-facing nodes
# -----------------------------------------------------------------------------
output "lb_public_ip" {
  description = "Public (Elastic) IP của Nginx load balancer — trỏ DNS A record vào đây"
  value       = aws_eip.lb.public_ip
}

output "lb_private_ip" {
  description = "Private IP của load balancer"
  value       = aws_instance.this["load-balancer-server"].private_ip
}

output "teleport_public_ip" {
  description = "Public IP của Teleport node"
  value       = aws_instance.this["teleport"].public_ip
}

output "teleport_private_ip" {
  description = "Private IP của Teleport node"
  value       = aws_instance.this["teleport"].private_ip
}

output "kong_public_ip" {
  description = "Public (Elastic) IP của Kong API Gateway — trỏ DNS API domain vào đây"
  value       = aws_eip.kong.public_ip
}

output "kong_private_ip" {
  description = "Private IP của Kong Gateway"
  value       = aws_instance.this["kong-gateway"].private_ip
}

# -----------------------------------------------------------------------------
# Kubernetes control-plane nodes
# -----------------------------------------------------------------------------
output "k8s_masters" {
  description = "Map of K8s master names → private IPs (cho Ansible inventory [k8s_masters])"
  value = {
    for name in ["k8s-master-1", "k8s-master-2", "k8s-master-3"] :
    name => aws_instance.this[name].private_ip
  }
}

# -----------------------------------------------------------------------------
# Kubernetes worker nodes
# -----------------------------------------------------------------------------
output "k8s_workers" {
  description = "Map of K8s worker names → private IPs (cho Ansible inventory [k8s_workers])"
  value = {
    for name in ["k8s-worker-1", "k8s-worker-2", "k8s-worker-3"] :
    name => aws_instance.this[name].private_ip
  }
}

# -----------------------------------------------------------------------------
# Storage nodes — GlusterFS cluster
# -----------------------------------------------------------------------------
output "storage_nodes" {
  description = "Map of storage node names → private IPs (cho Ansible inventory [storage_nodes])"
  value = {
    for name in ["storage-master-1", "storage-master-2", "storage-master-3"] :
    name => aws_instance.this[name].private_ip
  }
}

# -----------------------------------------------------------------------------
# Platform tools — private subnet
# -----------------------------------------------------------------------------
output "platform_tools" {
  description = "Map of platform tool names → private IPs (cho Ansible inventory [platform_tools])"
  value = {
    for name in ["gitlab-server", "harbor-server", "sonarqube-server", "rancher-server", "dev-server"] :
    name => aws_instance.this[name].private_ip
  }
}

# -----------------------------------------------------------------------------
# ELK Stack node
# -----------------------------------------------------------------------------
output "elk_private_ip" {
  description = "Private IP của ELK node (Elasticsearch + Logstash + Kibana)"
  value       = aws_instance.this["elk"].private_ip
}

# -----------------------------------------------------------------------------
# Convenience: all private IPs keyed by instance name
# -----------------------------------------------------------------------------
output "all_private_ips" {
  description = "Tất cả private IPs, keyed by instance name (dùng cho Ansible inventory template)"
  value = {
    for name, instance in aws_instance.this :
    name => instance.private_ip
  }
}
