# =============================================================================
# Ansible Roles → Server Mapping
# =============================================================================
# Mỗi thư mục role tương ứng trực tiếp với 1 server hoặc 1 nhóm server.
# Không đặt tên chung chung — nhìn tên folder là biết ngay server nào.
# =============================================================================

roles/
├── common/                 → TẤT CẢ 16 servers (bootstrap chung)
├── ufw/                    → TẤT CẢ servers (firewall, port mở theo role)
│
├── load-balancer-server/   → load-balancer-server (Public DMZ)
│     Nginx reverse proxy, Certbot, route traffic đến internal services
│
├── kong-gateway/           → kong-gateway (Public DMZ)
│     Kong API Gateway + PostgreSQL, quản lý API routes + plugins
│
├── elk/                    → elk (Private Subnet)
│     Elasticsearch + Logstash + Kibana, thu thập & phân tích logs
│
├── storage-nodes/          → storage-master-1, storage-master-2, storage-master-3
│     GlusterFS replicated volume (3-node HA cluster)
│
└── (platform_tools)        → gitlab-server, harbor-server, sonarqube-server,
    (dùng tasks inline        rancher-server, dev-server
     trong site.yml)          Docker prerequisites, chưa có role riêng từng tool

# =============================================================================
# QUY ƯỚC ĐẶT TÊN:
#   - 1 server = 1 role folder (tên folder = tên server)
#   - Shared roles (common, ufw) có comment rõ áp dụng cho những server nào
#   - site.yml chia phase rõ ràng kèm tên server trong task name
# =============================================================================
