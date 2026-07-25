# =============================================================================
# Security Module — outputs.tf
# =============================================================================

output "sg_lb_id" {
  description = "Security group ID for the load balancer"
  value       = aws_security_group.load_balancer.id
}

output "sg_teleport_id" {
  description = "Security group ID for Teleport"
  value       = aws_security_group.teleport.id
}

output "sg_k8s_masters_id" {
  description = "Security group ID for Kubernetes control-plane nodes"
  value       = aws_security_group.k8s_masters.id
}

output "sg_internal_id" {
  description = "Security group ID for intra-VPC communication"
  value       = aws_security_group.internal_vpc.id
}

output "sg_kong_id" {
  description = "Security group ID for Kong API Gateway"
  value       = aws_security_group.kong_gateway.id
}

output "sg_elk_id" {
  description = "Security group ID for ELK Stack (Elasticsearch + Logstash + Kibana)"
  value       = aws_security_group.elk.id
}
