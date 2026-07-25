# DevOps Platform — Infrastructure as Code

Tài liệu giải thích toàn bộ cấu trúc thư mục Terraform & Ansible cho hệ thống **Self-hosted Cloud-Native DevOps Platform** trên AWS (`ap-southeast-1`).

---

## Kiến trúc tổng quan (19 EC2 Instances)

```
                            Internet
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
  shopnow.luo.io.vn   api-shopnow.luo.io.vn    (teleport, gitlab...)
   (Nginx EIP)          (Kong EIP)
        │                      │
  ┌─────┴─────┐          ┌─────┴─────┐
  │  PUBLIC   │          │  PUBLIC   │
  │  DMZ      │          │  DMZ      │
  │ (10.0.1.0/│          │ (10.0.1.0/│
  │   24)     │          │   24)     │
  ├───────────┤          ├───────────┤
  │ Nginx RP  │          │ Kong GW   │
  │ (EIP)     │          │ (EIP)     │
  └─────┬─────┘          └─────┬─────┘
        │                      │
        │    NAT GW            │
  ┌─────┴──────────────────────┴─────┐
  │         PRIVATE SUBNET           │
  │         (10.0.2.0/24)            │
  ├──────────────────────────────────┤
  │  PLATFORM TOOLS (6):             │
  │   gitlab-server   harbor-server  │
  │   sonarqube-server rancher-server│
  │   dev-server       elk           │
  ├──────────────────────────────────┤
  │  K8s CLUSTER (6 nodes):          │
  │   k8s-master-1,2,3 (control)     │
  │   k8s-worker-1,2,3 (workload) 🆕 │
  │   ┌──────────────────────────┐   │
  │   │ ShopNow on K8s:          │   │
  │   │  api-gateway (5860)      │   │
  │   │  discovery-server (8761) │   │
  │   │  config-server (5859)    │   │
  │   │  product-service (5861)  │   │
  │   │  shopping-cart (5863)    │   │
  │   │  user-service (5865)     │   │
  │   │  keycloak (8080)         │   │
  │   │  postgres (5432)         │   │
  │   │  mysql (3306)            │   │
  │   │  frontend (80)           │   │
  │   └──────────────────────────┘   │
  ├──────────────────────────────────┤
  │  STORAGE HA (3):                 │
  │   storage-master-1,2,3           │
  │   GlusterFS → K8s PV             │
  └──────────────────────────────────┘
```

---

## Cây thư mục tổng quan

```
DevOps_Scripts/
├── .gitignore                        # Ignore Terraform state, tfvars, node_modules...
├── README.md                         ← BẠN ĐANG Ở ĐÂY
│
├── iac/                              # Infrastructure as Code
│   │
│   ├── terraform/                    # Provision CƠ SỞ HẠ TẦNG (AWS)
│   │   │                              # Tạo VPC, subnet, security group, EC2...
│   │   ├── 🏗️ MODULES/               # Code tái sử dụng — mỗi module là 1 "bộ phận"
│   │   │   ├── network/              # MẠNG: VPC, subnets, IGW, NAT, route tables
│   │   │   ├── security/             # BẢO MẬT: 7 Security Groups
│   │   │   └── compute/              # MÁY CHỦ: 19 EC2 instances + EIP
│   │   │
│   │   └── 📄 ROOT FILES/           # Kết nối các module với nhau
│   │       ├── providers.tf          # Terraform + AWS provider config
│   │       ├── data.tf               # AMI lookup (Ubuntu 22.04 mới nhất)
│   │       ├── variables.tf          # Khai báo tất cả biến đầu vào
│   │       ├── main.tf               # Kết nối 3 module: network → security → compute
│   │       ├── outputs.tf            # Xuất IPs → Ansible inventory
│   │       ├── inventory.tf          # Tự động sinh file Ansible hosts.yml
│   │       ├── terraform.tfvars.example  # File biến mẫu (copy → terraform.tfvars)
│   │       └── templates/
│   │           └── inventory.yml.tpl # Template Ansible inventory
│   │
│   └── ansible/                      # Cấu hình PHẦN MỀM (OS-level)
│       │                              # Cài Nginx, Kong, ELK, K8s, GlusterFS...
│       ├── ansible.cfg               # Cấu hình Ansible toàn cục
│       ├── site.yml                  # Master playbook — 6 phases
│       ├── group_vars/
│       │   └── all.yml               # Biến toàn cục cho tất cả roles
│       ├── inventory/
│       │   └── .gitkeep              # hosts.yml sẽ được Terraform tạo ra
│       └── roles/                    # Mỗi folder = công thức cài đặt cho 1 server
│           ├── README.md             # Map role → server
│           ├── common/               → ALL    19 servers  (bootstrap chung)
│           ├── ufw/                  → ALL    19 servers  (firewall OS-level)
│           ├── load-balancer-server/  → load-balancer-server   (Nginx RP)
│           ├── kong-gateway/          → kong-gateway           (API Gateway)
│           ├── elk/                   → elk                    (Logging Stack)
│           ├── k8s-bootstrap/    🆕   → k8s-master-1,2,3       (containerd + kubeadm)
│           │                          → k8s-worker-1,2,3       (join cluster)
│           └── storage-nodes/         → storage-master-1,2,3   (GlusterFS HA)
│
└── Shopnow_k8s/                      # Ứng dụng E-Commerce Microservices
    │
    ├── build-and-push.sh             # Script build Docker images + push Harbor
    │
    ├── shopnow-backend/              # Spring Boot Microservices (Java 17)
    │   ├── docker-compose.yaml       # Docker Compose cho dev local
    │   ├── api-gateway/              # Spring Cloud Gateway (port 5860)
    │   ├── config-server/            # Spring Cloud Config (port 5859)
    │   ├── discovery-server/         # Netflix Eureka (port 8761)
    │   ├── product-service/          # Product CRUD (port 5861)
    │   ├── shopping-cart-service/    # Cart Management (port 5863)
    │   ├── user-service/             # User + JWT Auth (port 5865)
    │   ├── keycloak-realms/          # Realm cấu hình Keycloak
    │   └── product-data.sql          # Data mẫu sản phẩm
    │
    ├── shopnow-frontend/             # ReactJS Frontend (Node 18 + Nginx)
    │   ├── Dockerfile                # Multi-stage build
    │   ├── .env                      # REACT_APP_BASE_API_URL
    │   └── src/                      # Components, services, reducers
    │
    └── k8s-manifests/           🆕   # Kubernetes Deployment Manifests
        ├── deploy.sh                 # Script deploy toàn bộ lên K8s
        ├── 01-namespace.yaml         # Namespace "shopnow"
        ├── 02-secrets.yaml           # DB credentials + Keycloak admin
        ├── 03-configmaps.yaml        # Spring Cloud Config files
        ├── 04-glusterfs-storage.yaml # PVs + PVCs (GlusterFS backend)
        ├── 05-postgres.yaml          # PostgreSQL Deployment + Service
        ├── 06-mysql.yaml             # MySQL 5.7 Deployment + Service
        ├── 07-keycloak.yaml          # Keycloak 23 + NodePort 30004
        ├── 08-discovery-server.yaml  # Eureka + NodePort 30003
        ├── 09-config-server.yaml     # Spring Cloud Config + Service
        ├── 10-api-gateway.yaml       # API Gateway + NodePort 30001
        ├── 11-product-service.yaml   # Product Service + Service
        ├── 12-shopping-cart-service.yaml  # Cart Service + Service
        ├── 13-user-service.yaml      # User Service + Service
        └── 14-frontend.yaml          # React Frontend + NodePort 30002
```

---

## Terraform — chi tiết từng file

### `providers.tf` — Khai báo môi trường

| Mục | Giá trị | Giải thích |
|---|---|---|
| Terraform version | `>= 1.5.0` | Dùng syntax mới (ví dụ: `aws_vpc_security_group_ingress_rule`) |
| AWS Provider | `~> 5.0` | Nói chuyện với AWS API |
| Region | `ap-southeast-1` | Singapore |
| Default tags | `Environment`, `Project`, `ManagedBy` | Tự động gắn tag cho mọi resource |

### `data.tf` — Tra cứu dữ liệu từ AWS

Tự động tìm **AMI Ubuntu 22.04 LTS** mới nhất từ Canonical (`099720109477`). Không hardcode AMI ID — mỗi lần chạy luôn lấy bản mới nhất, tránh lỗi bảo mật.

### `variables.tf` — Biến đầu vào

| Biến | Mặc định | Ghi chú |
|---|---|---|
| `aws_region` | `ap-southeast-1` | Singapore |
| `environment` | `prod` | Validate: dev / staging / prod |
| `vpc_cidr` | `10.0.0.0/16` | 65,536 IPs |
| `public_subnet_cidr` | `10.0.1.0/24` | DMZ — 256 IPs |
| `private_subnet_cidr` | `10.0.2.0/24` | Nội bộ — 256 IPs |
| `ssh_key_name` | *(bắt buộc)* | EC2 Key Pair đã tạo sẵn |
| `ssh_allowed_cidrs` | `["0.0.0.0/0"]` | **Đổi thành IP công ty trước khi deploy** |

### `main.tf` — File chính, nối 3 module

```
module "network"   → tạo VPC + subnets + NAT
module "security"  → tạo 6 security groups (dùng VPC từ module trên)
module "compute"   → tạo 19 EC2 (dùng subnet + SG từ 2 module trên)

→ Dữ liệu truyền giữa các module qua outputs
→ VD: network xuất subnet_id → compute nhận vào để đặt EC2 đúng chỗ
```

### `outputs.tf` — Thông tin sau khi provision

| Output | Nội dung |
|---|---|
| `load_balancer_public_ip` | Public IP của Nginx — trỏ DNS record vào đây |
| `teleport_public_ip` | Public IP của Teleport |
| `kong_gateway_public_ip` | Public IP của Kong API Gateway |
| `elk_private_ip` | Private IP của ELK (truy cập nội bộ qua VPN/Teleport) |
| `ansible_inventory_*` | Từng group inventory cho Ansible |
| `ansible_inventory_flat` | Map phẳng: tên server → private IP |

### `inventory.tf` — Cầu nối Terraform → Ansible

Dùng `local_file` resource ghi file `hosts.yml` tự động sau mỗi lần `terraform apply`. Không cần copy-paste IP thủ công — tránh sai sót.

---

## Terraform Modules — chi tiết

### Module `network/` — Hạ tầng mạng

```
network/
├── variables.tf        # Input: CIDR blocks, availability zone
├── main.tf             # Resources:
│   aws_vpc             # VPC + DNS hostname (cần cho Rancher)
│   aws_internet_gateway# Internet Gateway
│   aws_eip             # Elastic IP cho NAT
│   aws_nat_gateway     # NAT Gateway (private → internet)
│   aws_subnet.public   # 10.0.1.0/24 (DMZ, auto-assign public IP)
│   aws_subnet.private  # 10.0.2.0/24 (nội bộ)
│   aws_route_table     # 2 bảng định tuyến (public → IGW, private → NAT)
│   aws_route_table_association  # Gắn route table vào subnet
└── outputs.tf          # vpc_id, subnet_ids, route_table_ids
```

**Tại sao tách riêng?** → Khi cần thêm AZ, đổi CIDR, hoặc tái dùng VPC cho project khác, chỉ cần sửa 1 module.

### Module `security/` — Tường lửa (Security Groups)

6 Security Groups theo nguyên tắc **least privilege** (chỉ mở port cần thiết):

| SG | Gắn cho server | Port mở |
|---|---|---|
| `sg-lb` | load-balancer-server | 80, 443 từ 0.0.0.0/0 |
| `sg-teleport` | teleport | 22 (restricted), 443, 3023-3025 |
| `sg-k8s-masters` | k8s-master-1,2,3 | 6443, 2379-2380, 10250-10259, **30000-32767** |
| `sg-k8s-workers` 🆕 | k8s-worker-1,2,3 | 10250 (kubelet), **30000-32767** (NodePort) |
| `sg-kong` | kong-gateway | 8000, 8443 (proxy), 8001 (admin), 8002 (GUI) |
| `sg-elk` | elk | 9200, 9300 (ES), 5601 (Kibana), 5044 (Beats) |
| `sg-internal` | TẤT CẢ server | All traffic trong VPC CIDR |

Dùng `aws_vpc_security_group_ingress_rule` (AWS Provider 5.x) — không dùng inline `ingress` block deprecated.

### Module `compute/` — Máy chủ EC2

**Cấu trúc chính: map + for_each**

```hcl
locals {
  instances = {
    "load-balancer-server" = { type="t3.micro",  disk=8,  subnet="public",  role="load-balancer" }
    "teleport"             = { type="t3.medium", disk=12, subnet="public",  role="teleport" }
    "kong-gateway"         = { type="t3.medium", disk=16, subnet="public",  role="kong-gateway" }
    "gitlab-server"        = { type="t3.large",  disk=16, subnet="private", role="gitlab" }
    "harbor-server"        = { type="t3.medium", disk=12, subnet="private", role="harbor" }
    "sonarqube-server"     = { type="t3.medium", disk=12, subnet="private", role="sonarqube" }
    "rancher-server"       = { type="t3.large",  disk=30, subnet="private", role="rancher" }
    "dev-server"           = { type="t3.large",  disk=18, subnet="private", role="cicd-runner" }
    "elk"                  = { type="t3.large",  disk=30, subnet="private", role="elk" }
    "k8s-master-1"         = { type="t3.medium", disk=10, subnet="private", role="k8s-master" }
    "k8s-master-2"         = { type="t3.medium", disk=10, subnet="private", role="k8s-master" }
    "k8s-master-3"         = { type="t3.medium", disk=10, subnet="private", role="k8s-master" }
    "storage-master-1"     = { type="t3.micro",  disk=8,  subnet="private", role="storage-node" }
    "storage-master-2"     = { type="t3.micro",  disk=8,  subnet="private", role="storage-node" }
    "storage-master-3"     = { type="t3.micro",  disk=8,  subnet="private", role="storage-node" }
  }
}

resource "aws_instance" "this" {
  for_each = local.instances    # 1 block code → 19 servers
  # ... tự động chọn subnet, SG theo role
}
```

**Phân bổ server theo subnet:**

| Subnet | Server | Instance Type | Disk |
|---|---|---|---|
| **Public (DMZ)** | load-balancer-server | t3.micro | 8 GB |
| | teleport | t3.medium | 12 GB |
| | kong-gateway | t3.medium | 16 GB |
| **Private** | gitlab-server | t3.large | 16 GB |
| | harbor-server | t3.medium | 12 GB |
| | sonarqube-server | t3.medium | 12 GB |
| | rancher-server | t3.large | 30 GB |
| | dev-server | t3.large | 18 GB |
| | elk | t3.large | 30 GB |
| | k8s-master-1 | t3.medium | 10 GB |
| | k8s-master-2 | t3.medium | 10 GB |
| | k8s-master-3 | t3.medium | 10 GB |
| | k8s-worker-1 🆕 | t3.medium | 20 GB |
| | k8s-worker-2 🆕 | t3.medium | 20 GB |
| | k8s-worker-3 🆕 | t3.medium | 20 GB |
| | storage-master-1 | t3.micro | 8 GB |
| | storage-master-2 | t3.micro | 8 GB |
| | storage-master-3 | t3.micro | 8 GB |

Security group tự động chọn theo role:
- `load-balancer` → gắn `sg_lb` + `sg_internal`
- `k8s-master` → gắn `sg_k8s_masters` + `sg_internal`
- `kong-gateway` → gắn `sg_kong` + `sg_internal`
- `k8s-worker` → gắn `sg_k8s_workers` + `sg_internal`
- `elk` → gắn `sg_elk` + `sg_internal`
- Còn lại → chỉ `sg_internal`

Elastic IP: chỉ gắn cho **load-balancer-server** và **kong-gateway** (2 server public-facing).

Root volume: **gp3, encrypted** (bảo mật dữ liệu at-rest).

User data (cloud-init): cài `python3`, `python3-apt`, `haveged`, set hostname, tắt unattended-upgrades trong lúc provision.

---

## Ansible — chi tiết từng file

### `ansible.cfg` — Cấu hình Ansible toàn cục

| Setting | Giá trị | Ý nghĩa |
|---|---|---|
| `inventory` | `./inventory/hosts.yml` | File danh sách server (auto-generated) |
| `host_key_checking` | `False` | Không hỏi confirm SSH lần đầu |
| `pipelining` | `True` | Gộp nhiều lệnh vào 1 SSH connection → nhanh hơn |
| `gathering` | `smart` | Chỉ collect facts khi cần |
| `fact_caching` | `jsonfile` | Cache facts → chạy lại nhanh hơn |
| `stdout_callback` | `yaml` | Output dạng YAML dễ đọc |

### `site.yml` — Master Playbook (6 phases)

```
PHASE 0 ─ [ALL 19 servers]
          └── common: base packages, NTP, kernel tuning

PHASE 1 ─ [Public DMZ — 3 servers]
          ├── load-balancer-server: ufw + Nginx reverse proxy
          │     Upstreams: gitlab, harbor, sonarqube, rancher, kibana, shopnow-frontend
          ├── teleport:             ufw (chuẩn bị Teleport)
          └── kong-gateway:         ufw + Kong API Gateway + PostgreSQL
                Routes: gitlab, harbor, sonarqube, rancher + ShopNow (6 routes)

PHASE 2 ─ [Private Platform Tools — 6 servers]
          ├── platform_tools:       ufw + Docker prerequisites
          │   (gitlab, harbor, sonarqube, rancher, dev-server)
          └── elk:                  ufw + Elasticsearch + Logstash + Kibana

PHASE 3 ─ [K8s Cluster — 6 servers] 🆕
          ├── k8s_masters:          ufw + swap off + kernel modules
          │   + k8s-bootstrap role (containerd + kubeadm init/join + Calico CNI)
          │   (k8s-master-1, k8s-master-2, k8s-master-3)
          └── k8s_workers:          ufw + swap off + kernel modules
              + k8s-bootstrap role (containerd + kubeadm join)
              (k8s-worker-1, k8s-worker-2, k8s-worker-3)

PHASE 4 ─ [Storage Cluster — 3 servers]
          └── storage_nodes:        GlusterFS replicated volume
              (serial: 1 — từng node một)
```

### `group_vars/all.yml` — Biến toàn cục

| Biến | Dùng bởi |
|---|---|
| `internal_services` | Nginx reverse proxy, Kong Gateway (IP:port của backend services) |
| `glusterfs` | storage-nodes role (tên volume, brick path, replicas) |
| `nginx` | load-balancer-server role (worker connections, SSL) |
| `kong_db_password` | kong-gateway role (PostgreSQL password) |
| `k8s_first_worker_ip` 🆕 | Kong & Nginx — trỏ đến K8s NodePort services |
| `ufw_default_policy` | ufw role (default deny) |

---

## Ansible Roles — chi tiết

Mỗi role = 1 công thức cài đặt hoàn chỉnh cho 1 server/nhóm server. Cấu trúc chuẩn:

```
roles/<tên-server>/
├── tasks/main.yml      # Các bước cài đặt (BẮT BUỘC)
├── handlers/main.yml   # Hành động khi config thay đổi (restart service...)
├── templates/*.j2      # File cấu hình mẫu (Jinja2 template)
└── vars/main.yml       # Biến riêng của role (không bắt buộc)
```

### Role `common/` → TẤT CẢ 19 servers

| Bước | Hành động | Tại sao |
|---|---|---|
| 1 | `apt update` (cache 3600s) | Không gọi lại nếu cache còn hạn |
| 2 | Cài base packages | `htop`, `net-tools`, `curl`, `git`, `python3`, `jq`... |
| 3 | Bật NTP + sync time | Đồng bộ giờ — sống còn với K8s, GlusterFS, GitLab |
| 4 | Set timezone UTC | Chuẩn cho distributed systems |
| 5 | `vm.swappiness = 1` | Giảm swap, tăng performance |
| 6 | File descriptor limit 65536 | Cần cho high-traffic services |
| 7 | Bật unattended-upgrades | Tự động cài security patches |

### Role `ufw/` → TẤT CẢ 19 servers

| Bước | Mô tả |
|---|---|
| 1 | Cài UFW, set default policy: deny incoming, allow outgoing |
| 2 | Mở port 22 (SSH) — tất cả server |
| 3 | Mở port theo role (dùng `when: condition`): |

| Server Group | Ports mở |
|---|---|
| `load_balancers` | 80, 443 |
| `teleport` | 443, 3023, 3024, 3025 |
| `kong_gateway` | 8000, 8001, 8002, 8443, 8444 |
| `k8s_masters` | 6443, 2379, 2380, 10250, 10257, 10259 |
| `elk` | 9200, 9300, 5601, 5044, 9600 |
| `storage_nodes` | 24007, 24008, 49152 |
| `k8s_workers` 🆕 | 10250, 30000-32767 |

### Role `load-balancer-server/` → Nginx Reverse Proxy

Server quan trọng nhất — toàn bộ traffic từ internet đi qua đây.

| Bước | Hành động |
|---|---|
| 1 | Thêm Nginx **official repo** (mainline, không dùng distro cũ) |
| 2 | Cài Nginx |
| 3 | Xóa `default` config |
| 4 | Tạo thư mục `/var/www/certbot` (webroot cho Let's Encrypt) |
| 5 | Deploy `nginx.conf` từ Jinja2 template — **validate bằng `nginx -t` trước khi apply** |
| 6 | Start + enable Nginx |
| 7 | (Comment sẵn) Certbot block — bỏ comment khi DNS đã trỏ |

**Template `nginx.conf.j2` tạo ra:**
- 5 upstream blocks (gitlab, harbor, sonarqube, rancher, kibana)
- 5 server blocks (mỗi domain → upstream tương ứng)
- WebSocket support (cần cho Rancher, GitLab Web IDE)
- JSON log format (để ELK parse)
- Default server → `return 444` (drop connection, không lộ thông tin)
- `client_max_body_size 512m` (đủ cho Docker images, Git LFS)

### Role `kong-gateway/` → API Gateway

| Bước | Hành động |
|---|---|
| 1 | Cài PostgreSQL, tạo user `kong` + database `kong` |
| 2 | Thêm Kong repo → cài Kong Gateway |
| 3 | Deploy `kong.conf` từ template (database, proxy ports, plugins) |
| 4 | Chạy `kong migrations bootstrap` — **chỉ lần đầu** (idempotent guard) |
| 5 | Start Kong |
| 6 | Deploy `kong.yml` — declarative config (services, routes, CORS, rate-limiting) |
| 7 | Health check — chờ Kong Admin API sẵn sàng |

### Role `elk/` → Elasticsearch + Logstash + Kibana

| Bước | Hành động |
|---|---|
| 1 | Cài OpenJDK 17 (Elasticsearch + Logstash cần Java) |
| 2 | Thêm Elastic 8.x APT repo |
| 3 | Cài Elasticsearch → cấu hình single-node → set JVM heap 2GB → start |
| 4 | Cài Kibana → kết nối `localhost:9200` → start |
| 5 | Cài Logstash → Beats input (port 5044) → Elasticsearch output → start |
| 6 | Health check trước mỗi bước để đảm bảo service trước đã sẵn sàng |

### Role `storage-nodes/` → GlusterFS HA Cluster

| Bước | Hành động | Chạy trên |
|---|---|---|
| 1 | Cài `glusterfs-server` (version 11) | Cả 3 node |
| 2 | Start `glusterd` | Cả 3 node |
| 3 | Tạo brick dir `/data/glusterfs/brick` | Cả 3 node |
| 4 | Peer probe 2 node còn lại | Chỉ node-1 |
| 5 | Tạo volume `gv0` replica 3 | Chỉ node-1 |
| 6 | Start volume | Chỉ node-1 |
| 7 | Tuning (cache 256MB, quorum auto) | Chỉ node-1 |
| 8 | Mount `/mnt/glusterfs` qua fstab | Cả 3 node |

> **Quan trọng:** `serial: 1` trong site.yml — triển khai tuần tự từng node để tránh race condition khi tạo cluster.

---

## Quy ước đặt tên

| Quy ước | Ví dụ |
|---|---|
| Tên role = tên server | `load-balancer-server/`, `kong-gateway/`, `elk/` |
| Tên role = tên nhóm server | `storage-nodes/` (cho storage-master-1,2,3) |
| Shared role có comment rõ phạm vi | `common/` → "ALL 19 servers" |
| Phase trong site.yml ghi rõ tên server | `[load-balancer-server] Cài đặt Nginx...` |
| Mọi file đều có header comment giải thích | `# ===== Role X — tasks/main.yml =====` |

---

## Luồng deploy

```bash
# ─── Bước 1: Provision hạ tầng AWS ─────────────────────────────
cd iac/terraform
cp terraform.tfvars.example terraform.tfvars
# → Sửa ssh_key_name + ssh_allowed_cidrs

terraform init && terraform plan && terraform apply
# → Output public IPs + tự động ghi ansible inventory (19 servers)

# ─── Bước 2: Cấu hình OS + bootstrap K8s ───────────────────────
cd ../ansible
ansible-playbook site.yml --limit k8s_masters,k8s_workers
# → Cài containerd + kubeadm → init cluster → join nodes → Calico CNI

# ─── Bước 3: Verify K8s cluster ────────────────────────────────
ssh k8s-master-1
kubectl get nodes            # 6 nodes Ready
kubectl get pods -A          # Tất cả system pods Running

# ─── Bước 4: Build & push Docker images lên Harbor ─────────────
cd ../../Shopnow_k8s
./build-and-push.sh
# → Build 7 images (6 backend + 1 frontend) → push Harbor

# ─── Bước 5: Deploy ShopNow lên K8s ────────────────────────────
cd k8s-manifests
# Sửa STORAGE_MASTER_*_IP trong 04-glusterfs-storage.yaml
./deploy.sh
# → Deploy namespace, secrets, configs, PVs, 8 components

# ─── Bước 6: Cập nhật Kong + Nginx config ──────────────────────
cd ../../iac/ansible
ansible-playbook site.yml --limit kong_gateway --tags kong
ansible-playbook site.yml --limit load_balancers --tags nginx,config

# ─── Bước 7: DNS ───────────────────────────────────────────────
# Trỏ các domain về EIP tương ứng:
#   shopnow.luo.io.vn                    → Nginx EIP
#   api-shopnow.luo.io.vn                → Kong EIP
#   discovery-server-shopnow.luo.io.vn   → Kong EIP
#   keycloak-shopnow.luo.io.vn           → Kong EIP
#   product-service-shopnow.luo.io.vn    → Kong EIP
#   cart-service-shopnow.luo.io.vn       → Kong EIP
#   user-service-shopnow.luo.io.vn       → Kong EIP

# ─── Bước 8: Verify ────────────────────────────────────────────
curl http://shopnow.luo.io.vn                          # Frontend
curl http://api-shopnow.luo.io.vn/api/product          # API (cần JWT)
curl http://discovery-server-shopnow.luo.io.vn         # Eureka dashboard
curl http://keycloak-shopnow.luo.io.vn                 # Keycloak admin
```

---

## ShopNow Domain Mapping

Tất cả domain dùng chung base `luo.io.vn`. Cấu hình DNS: trỏ tất cả về **Nginx EIP** hoặc **Kong EIP** như bảng dưới.

| Domain | Trỏ đến | Backend | NodePort |
|---|---|---|---|
| `shopnow.luo.io.vn` | **Nginx EIP** | React Frontend (nginx:80) | `30002` |
| `api-shopnow.luo.io.vn` | **Kong EIP** | Spring Cloud Gateway (:5860) | `30001` |
| `discovery-server-shopnow.luo.io.vn` | **Kong EIP** | Eureka Dashboard (:8761) | `30003` |
| `keycloak-shopnow.luo.io.vn` | **Kong EIP** | Keycloak Admin (:8080) | `30004` |
| `product-service-shopnow.luo.io.vn` | **Kong EIP** | Spring Cloud Gateway → Product Service | `30001` |
| `cart-service-shopnow.luo.io.vn` | **Kong EIP** | Spring Cloud Gateway → Cart Service | `30001` |
| `user-service-shopnow.luo.io.vn` | **Kong EIP** | Spring Cloud Gateway → User Service | `30001` |
| `gitlab.luo.io.vn` | **Nginx EIP** | gitlab-server | — |
| `registry.luo.io.vn` | **Nginx EIP** | harbor-server | — |
| `sonar.luo.io.vn` | **Nginx EIP** | sonarqube-server | — |
| `rancher.luo.io.vn` | **Nginx EIP** | rancher-server | — |
| `kibana.luo.io.vn` | **Nginx EIP** | elk (Kibana :5601) | — |

---

## Ngôn ngữ sử dụng

| File | Ngôn ngữ | Mục đích |
|---|---|---|
| `*.tf` | **HCL** (HashiCorp Configuration Language) | Terraform — provision AWS resources |
| `*.yml` | **YAML** (Ansible Playbook DSL) | Ansible — cấu hình OS, cài services |
| `*.j2` | **Jinja2 Template** | Template engine — sinh file cấu hình động |

---

## Git commit convention

```bash
# Commit 1: Terraform
git add iac/terraform/
git commit -m "feat(terraform): provision AWS infrastructure — VPC, 7 SG, 19 EC2"

# Commit 2: Ansible
git add iac/ansible/
git commit -m "feat(ansible): configure 19 servers — K8s bootstrap + Nginx + Kong"

# Commit 3: ShopNow app
git add Shopnow_k8s/
git commit -m "feat(shopnow): add e-commerce microservices + K8s manifests"

# Commit 4: Docs
git add README.md .gitignore
git commit -m "docs: update README with full architecture + .gitignore"
```
