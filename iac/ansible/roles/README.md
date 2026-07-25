# =============================================================================
# Ansible Roles → Server Mapping
# =============================================================================
# Mỗi thư mục role tương ứng trực tiếp với 1 server hoặc 1 nhóm server.
# Không đặt tên chung chung — nhìn tên folder là biết ngay server nào.
# =============================================================================

roles/
├── common/                  → TẤT CẢ 16 servers (bootstrap chung)
├── ufw/                     → TẤT CẢ servers (firewall, port mở theo role)
│
├── load-balancer-server/    → load-balancer-server (Public DMZ)
│     Nginx reverse proxy, Certbot, route traffic đến internal services
│     Upstreams: gitlab, harbor, sonarqube, rancher, kibana, shopnow-frontend
│
├── kong-gateway/            → kong-gateway (Public DMZ)
│     Kong API Gateway + PostgreSQL, quản lý API routes + plugins
│     Routes: gitlab, harbor, sonarqube, rancher + ShopNow (7 routes)
│
├── rancher-server/     🆕   → rancher-server (Private Subnet)
│     Docker + Rancher container — K8s Cluster Management UI
│
├── elk/                     → elk (Private Subnet)
│     Elasticsearch + Logstash + Kibana, thu thập & phân tích logs
│
├── k8s-bootstrap/           → k8s-master-1,2,3 (3 nodes = master + worker)
│     Cài containerd + kubeadm/kubelet/kubectl → kubeadm init/join → Calico CNI
│     3 node vừa control-plane vừa workload (bỏ taint), disk 20GB
│
├── storage-nodes/           → storage-master-1, storage-master-2, storage-master-3
│     GlusterFS replicated volume (3-node HA cluster)
│
└── (platform_tools)         → gitlab-server, harbor-server, sonarqube-server,
    (dùng tasks inline         dev-server
     trong site.yml)           Docker prerequisites, chưa có role riêng từng tool

# =============================================================================
# QUY ƯỚC ĐẶT TÊN:
#   - 1 server = 1 role folder (tên folder = tên server)
#   - Shared roles (common, ufw) có comment rõ áp dụng cho những server nào
#   - site.yml chia phase rõ ràng kèm tên server trong task name
# =============================================================================

# =============================================================================
# SHOPNOW INTEGRATION — 3 tầng proxy
# =============================================================================
#
# TẤT CẢ domain ShopNow → Kong EIP → 1 upstream → K8s master IP:30080
# Ingress NGINX đọc Host header → route đến ClusterIP Service.
#
# Kong (Tầng 1)  = bảo vệ: CORS, Rate Limit, IP Restrict, Cache, Security Headers
# Ingress (Tầng 2) = route hostname → Service
# Spring GW (Tầng 3) = route path → microservice nội bộ
#
# 3 node K8s (master+worker, disk 20GB):
#   k8s-master-1,2,3 vừa chạy etcd+apiserver vừa chạy ShopNow pods
#   Bỏ taint control-plane để schedule workload lên cả 3 node
# =============================================================================
