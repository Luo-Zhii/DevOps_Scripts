# =============================================================================
# Ansible Roles → Server Mapping
# =============================================================================
# Mỗi thư mục role tương ứng trực tiếp với 1 server hoặc 1 nhóm server.
# Không đặt tên chung chung — nhìn tên folder là biết ngay server nào.
# =============================================================================

roles/
├── common/                  → TẤT CẢ 19 servers (bootstrap chung)
├── ufw/                     → TẤT CẢ servers (firewall, port mở theo role)
│
├── load-balancer-server/    → load-balancer-server (Public DMZ)
│     Nginx reverse proxy, Certbot, route traffic đến internal services
│     Upstreams: gitlab, harbor, sonarqube, rancher, kibana, shopnow-frontend
│
├── kong-gateway/            → kong-gateway (Public DMZ)
│     Kong API Gateway + PostgreSQL, quản lý API routes + plugins
│     Routes: gitlab, harbor, sonarqube, rancher, shopnow-api-gateway
│
├── elk/                     → elk (Private Subnet)
│     Elasticsearch + Logstash + Kibana, thu thập & phân tích logs
│
├── k8s-bootstrap/      🆕   → k8s-master-1,2,3 + k8s-worker-1,2,3 (6 nodes)
│     Cài containerd + kubeadm/kubelet/kubectl → kubeadm init/join → Calico CNI
│     → Tạo Kubernetes cluster 6 nodes sẵn sàng chạy workload
│
├── storage-nodes/           → storage-master-1, storage-master-2, storage-master-3
│     GlusterFS replicated volume (3-node HA cluster)
│
└── (platform_tools)         → gitlab-server, harbor-server, sonarqube-server,
    (dùng tasks inline         rancher-server, dev-server
     trong site.yml)           Docker prerequisites, chưa có role riêng từng tool

# =============================================================================
# QUY ƯỚC ĐẶT TÊN:
#   - 1 server = 1 role folder (tên folder = tên server)
#   - Shared roles (common, ufw) có comment rõ áp dụng cho những server nào
#   - site.yml chia phase rõ ràng kèm tên server trong task name
# =============================================================================

# =============================================================================
# SHOPNOW INTEGRATION — Kiến trúc triển khai (dùng K8s Ingress)
# =============================================================================
#
# TẤT CẢ traffic ShopNow → Kong EIP → 1 upstream duy nhất → K8s Ingress :30080
# Ingress Controller (NGINX) đọc Host header và route đến đúng ClusterIP Service.
#
# Flow tổng:
#   Browser → Kong EIP :8000
#          → K8s Worker NodePort 30080
#          → Ingress NGINX (đọc Host header)
#          → Route đến Service:
#               shopnow.luo.io.vn                → shopnow-frontend:80
#               api-shopnow.luo.io.vn            → api-gateway:5860
#               discovery-server-shopnow...      → shopnow-discovery-server-service:8761
#               keycloak-shopnow...              → keycloak:8080
#               product-service-shopnow...       → product-service:5861
#               cart-service-shopnow...          → shopping-cart-service:5863
#               user-service-shopnow...          → user-service:5865
#
# KHÔNG dùng nhiều NodePort riêng lẻ nữa. Chỉ 1 NodePort 30080 cho toàn bộ.
# =============================================================================
