# =============================================================================
# Security Module — main.tf
# =============================================================================
# Each security group is scoped to the minimum required ports following the
# principle of least privilege. Rules are documented inline.
# =============================================================================

# -----------------------------------------------------------------------------
# SG-1: Load Balancer — public-facing HTTP/HTTPS
# -----------------------------------------------------------------------------
resource "aws_security_group" "load_balancer" {
  name        = "${var.project_name}-sg-lb"
  description = "Public HTTP/HTTPS for the Nginx reverse proxy"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-lb"
    Environment = var.environment
    Role        = "load-balancer"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_http" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "lb_https" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow HTTPS from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "lb_out" {
  security_group_id = aws_security_group.load_balancer.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols
}

# -----------------------------------------------------------------------------
# SG-2: Teleport — SSH + Web Proxy ports
# -----------------------------------------------------------------------------
# Teleport defaults: 3023 (auth), 3024 (proxy SSH), 3025 (proxy K8s), 3080 (web)
# We also open 443 for its web UI behind Nginx and optionally 22 for bootstrap.
resource "aws_security_group" "teleport" {
  name        = "${var.project_name}-sg-teleport"
  description = "Teleport access management ports"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-teleport"
    Environment = var.environment
    Role        = "teleport"
  }
}

resource "aws_vpc_security_group_ingress_rule" "teleport_ssh" {
  security_group_id = aws_security_group.teleport.id
  description       = "SSH for initial bootstrap"
  cidr_ipv4         = var.ssh_allowed_cidrs[0] # Restrict in production
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "teleport_web" {
  security_group_id = aws_security_group.teleport.id
  description       = "Teleport Web UI"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "teleport_auth" {
  security_group_id = aws_security_group.teleport.id
  description       = "Teleport Auth service"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 3023
  to_port           = 3023
}

resource "aws_vpc_security_group_ingress_rule" "teleport_proxy_ssh" {
  security_group_id = aws_security_group.teleport.id
  description       = "Teleport Proxy SSH"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 3024
  to_port           = 3024
}

resource "aws_vpc_security_group_ingress_rule" "teleport_proxy_k8s" {
  security_group_id = aws_security_group.teleport.id
  description       = "Teleport Proxy K8s"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 3025
  to_port           = 3025
}

resource "aws_vpc_security_group_egress_rule" "teleport_out" {
  security_group_id = aws_security_group.teleport.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# SG-3: K8s Masters — Kubernetes API + internal cluster comms
# -----------------------------------------------------------------------------
resource "aws_security_group" "k8s_masters" {
  name        = "${var.project_name}-sg-k8s-masters"
  description = "Kubernetes control-plane nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-k8s-masters"
    Environment = var.environment
    Role        = "k8s-master"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "Kubernetes API server — reachable from LB and VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

# K8s etcd client API (used by kube-apiserver)
resource "aws_vpc_security_group_ingress_rule" "k8s_etcd" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "etcd client API"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 2379
  to_port           = 2380
}

# Kubelet API
resource "aws_vpc_security_group_ingress_rule" "k8s_kubelet" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "Kubelet API"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

# Kube-scheduler / kube-controller-manager
resource "aws_vpc_security_group_ingress_rule" "k8s_comp" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "K8s scheduler & controller-manager ports"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 10257
  to_port           = 10259
}

# NodePort range — cho Kong/Nginx từ DMZ truy cập service K8s
resource "aws_vpc_security_group_ingress_rule" "k8s_nodeports" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "K8s NodePort range for external access to services"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}

resource "aws_vpc_security_group_egress_rule" "k8s_masters_out" {
  security_group_id = aws_security_group.k8s_masters.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# SG-4: Internal VPC — open intra-VPC communication for all platform services
# -----------------------------------------------------------------------------
# This SG is attached to every private instance. It allows all traffic
# originating from within the VPC CIDR so that services (GitLab ↔ Harbor,
# Rancher ↔ K8s, Storage ↔ Platform) can talk freely.
resource "aws_security_group" "internal_vpc" {
  name        = "${var.project_name}-sg-internal"
  description = "Allow all traffic between internal VPC resources"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-internal"
    Environment = var.environment
    Role        = "internal"
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_in" {
  security_group_id = aws_security_group.internal_vpc.id
  description       = "Allow all inbound from within the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "internal_out" {
  security_group_id = aws_security_group.internal_vpc.id
  description       = "Allow all outbound to anywhere (needed for apt, Docker pulls, etc.)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# SG-5: Kong API Gateway — public-facing API management
# -----------------------------------------------------------------------------
# Kong ports: 8000 (HTTP proxy), 8443 (HTTPS proxy), 8001 (Admin API),
# 8444 (Admin HTTPS), 8002 (Admin GUI — Kong Manager)
resource "aws_security_group" "kong_gateway" {
  name        = "${var.project_name}-sg-kong"
  description = "Kong API Gateway — proxy + admin ports"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-kong"
    Environment = var.environment
    Role        = "kong-gateway"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kong_proxy_http" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Kong HTTP proxy port"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
}

resource "aws_vpc_security_group_ingress_rule" "kong_proxy_https" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Kong HTTPS proxy port"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8443
  to_port           = 8443
}

resource "aws_vpc_security_group_ingress_rule" "kong_admin" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Kong Admin API — restricted to VPC only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 8001
  to_port           = 8001
}

resource "aws_vpc_security_group_ingress_rule" "kong_admin_ssl" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Kong Admin HTTPS — restricted to VPC only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 8444
  to_port           = 8444
}

resource "aws_vpc_security_group_ingress_rule" "kong_manager" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Kong Manager GUI"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8002
  to_port           = 8002
}

resource "aws_vpc_security_group_egress_rule" "kong_out" {
  security_group_id = aws_security_group.kong_gateway.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# SG-6: ELK Stack — Elasticsearch + Logstash + Kibana
# -----------------------------------------------------------------------------
# ELK ports: 9200 (ES HTTP), 9300 (ES transport), 5601 (Kibana),
# 5044 (Logstash Beats input), 9600 (Logstash monitoring)
resource "aws_security_group" "elk" {
  name        = "${var.project_name}-sg-elk"
  description = "ELK Stack — Elasticsearch + Logstash + Kibana"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-elk"
    Environment = var.environment
    Role        = "elk"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elk_es_http" {
  security_group_id = aws_security_group.elk.id
  description       = "Elasticsearch HTTP API"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 9200
  to_port           = 9200
}

resource "aws_vpc_security_group_ingress_rule" "elk_es_transport" {
  security_group_id = aws_security_group.elk.id
  description       = "Elasticsearch transport (inter-node)"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 9300
  to_port           = 9300
}

resource "aws_vpc_security_group_ingress_rule" "elk_kibana" {
  security_group_id = aws_security_group.elk.id
  description       = "Kibana web UI"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 5601
  to_port           = 5601
}

resource "aws_vpc_security_group_ingress_rule" "elk_logstash_beats" {
  security_group_id = aws_security_group.elk.id
  description       = "Logstash Beats input (Filebeat, Metricbeat, etc.)"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 5044
  to_port           = 5044
}

resource "aws_vpc_security_group_egress_rule" "elk_out" {
  security_group_id = aws_security_group.elk.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# -----------------------------------------------------------------------------
# SG-7: K8s Workers — Kubelet + NodePort + pod-to-pod communication
# -----------------------------------------------------------------------------
resource "aws_security_group" "k8s_workers" {
  name        = "${var.project_name}-sg-k8s-workers"
  description = "Kubernetes worker nodes — kubelet + NodePort services"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-sg-k8s-workers"
    Environment = var.environment
    Role        = "k8s-worker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_kubelet" {
  security_group_id = aws_security_group.k8s_workers.id
  description       = "Kubelet API"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "k8s_worker_nodeports" {
  security_group_id = aws_security_group.k8s_workers.id
  description       = "NodePort services — Kong & Nginx truy cập từ DMZ qua private IP"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 30000
  to_port           = 32767
}

resource "aws_vpc_security_group_egress_rule" "k8s_workers_out" {
  security_group_id = aws_security_group.k8s_workers.id
  description       = "Allow all outbound traffic (Harbor pull, apt, etc.)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
