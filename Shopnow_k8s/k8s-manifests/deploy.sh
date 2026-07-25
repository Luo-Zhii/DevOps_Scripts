#!/bin/bash
# =============================================================================
# deploy.sh — Deploy toan bo ShopNow len Kubernetes
# =============================================================================
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh
#
# Yeu cau:
#   - kubectl da duoc cau hinh tro den K8s cluster
#   - Docker images da duoc build va push len Harbor
#   - File 04-glusterfs-storage.yaml da duoc cap nhat IP storage nodes
# =============================================================================
set -euo pipefail

K8S_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo " Deploying ShopNow to Kubernetes"
echo "============================================"

# Step 1: Namespace
echo ""
echo "[1/16] Creating namespace..."
kubectl apply -f "${K8S_DIR}/01-namespace.yaml"
kubectl get ns shopnow

# Step 2: Secrets
echo ""
echo "[2/16] Creating secrets..."
kubectl apply -f "${K8S_DIR}/02-secrets.yaml"

# Step 3: ConfigMaps
echo ""
echo "[3/16] Creating ConfigMaps..."
kubectl apply -f "${K8S_DIR}/03-configmaps.yaml"

# Step 4: Storage (GlusterFS PVs + PVCs)
echo ""
echo "[4/16] Setting up GlusterFS storage..."
kubectl apply -f "${K8S_DIR}/04-glusterfs-storage.yaml"

# Step 5: PostgreSQL
echo ""
echo "[5/16] Deploying PostgreSQL..."
kubectl apply -f "${K8S_DIR}/05-postgres.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=postgres --timeout=120s

# Step 6: MySQL
echo ""
echo "[6/16] Deploying MySQL..."
kubectl apply -f "${K8S_DIR}/06-mysql.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=keycloak-mysql --timeout=120s

# Step 7: Keycloak
echo ""
echo "[7/16] Deploying Keycloak..."
kubectl apply -f "${K8S_DIR}/07-keycloak.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=keycloak --timeout=180s

# Step 8: Discovery Server (Eureka)
echo ""
echo "[8/16] Deploying Discovery Server (Eureka)..."
kubectl apply -f "${K8S_DIR}/08-discovery-server.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=discovery-server --timeout=120s

# Step 9: Config Server
echo ""
echo "[9/16] Deploying Config Server..."
kubectl apply -f "${K8S_DIR}/09-config-server.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=config-server --timeout=120s

# Step 10: Product Service
echo ""
echo "[10/16] Deploying Product Service..."
kubectl apply -f "${K8S_DIR}/11-product-service.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=product-service --timeout=120s

# Step 11: Shopping Cart Service
echo ""
echo "[11/16] Deploying Shopping Cart Service..."
kubectl apply -f "${K8S_DIR}/12-shopping-cart-service.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=shopping-cart-service --timeout=120s

# Step 12: User Service
echo ""
echo "[12/16] Deploying User Service..."
kubectl apply -f "${K8S_DIR}/13-user-service.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=user-service --timeout=120s

# Step 13: API Gateway
echo ""
echo "[13/16] Deploying API Gateway..."
kubectl apply -f "${K8S_DIR}/10-api-gateway.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=api-gateway --timeout=120s

# Step 14: Frontend
echo ""
echo "[14/16] Deploying Frontend..."
kubectl apply -f "${K8S_DIR}/14-frontend.yaml"
kubectl -n shopnow wait --for=condition=Ready pod -l app=shopnow-frontend --timeout=60s

# Step 15: NGINX Ingress Controller (1 entrypoint duy nhat vao K8s)
echo ""
echo "[15/16] Deploying NGINX Ingress Controller..."
kubectl apply -f "${K8S_DIR}/15-ingress-nginx.yaml"
kubectl -n ingress-nginx wait --for=condition=Ready pod -l app.kubernetes.io/name=ingress-nginx --timeout=120s

# Step 16: Ingress Routes (hostname -> ClusterIP Service)
echo ""
echo "[16/16] Deploying Ingress Routes..."
kubectl apply -f "${K8S_DIR}/16-ingress-routes.yaml"

# Final status
echo ""
echo "============================================"
echo " Deployment Complete - Status"
echo "============================================"
kubectl -n shopnow get pods,svc,pvc
kubectl -n ingress-nginx get pods,svc
echo ""
echo "NodePort:"
echo "  Ingress NGINX (tat ca domain):  http://<any-worker-ip>:30080"
echo ""
echo "Next steps:"
echo "  1. Update Kong config -> 1 upstream duy nhat toi :30080"
echo "  2. Configure DNS A records (tat ca domain -> Kong EIP)"
