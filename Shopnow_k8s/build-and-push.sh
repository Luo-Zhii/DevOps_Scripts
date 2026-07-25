#!/bin/bash
# =============================================================================
# build-and-push.sh — Build Docker images & push lên Harbor Registry
# =============================================================================
# Usage:
#   chmod +x build-and-push.sh
#   ./build-and-push.sh
#
# Yêu cầu: Harbor đã được cài đặt và chạy trên harbor-server
# =============================================================================
set -euo pipefail

# --- Cấu hình Harbor ---
HARBOR_HOST="harbor-server"        # Private IP hoặc hostname của harbor-server
HARBOR_PROJECT="techcareer"        # Tên project trong Harbor
IMAGE_TAG="${1:-latest}"           # Tag, mặc định "latest"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)/shopnow-backend"
FRONTEND_DIR="$(cd "$(dirname "$0")" && pwd)/shopnow-frontend"

echo "============================================"
echo " Building & Pushing ShopNow Docker Images"
echo " Harbor: ${HARBOR_HOST}/${HARBOR_PROJECT}"
echo " Tag:    ${IMAGE_TAG}"
echo "============================================"

# Danh sách các microservices cần build
SERVICES=(
  "discovery-server:8761"
  "config-server:5859"
  "api-gateway:5860"
  "product-service:5861"
  "shopping-cart-service:5863"
  "user-service:5865"
)

# --- Build backend microservices ---
for service_info in "${SERVICES[@]}"; do
  IFS=':' read -r service_name service_port <<< "$service_info"
  echo ""
  echo "--- Building ${service_name} ---"
  cd "${BASE_DIR}/${service_name}"
  docker build -t "${HARBOR_HOST}/${HARBOR_PROJECT}/${service_name}:${IMAGE_TAG}" .
  echo "--- Pushing ${service_name} ---"
  docker push "${HARBOR_HOST}/${HARBOR_PROJECT}/${service_name}:${IMAGE_TAG}"
done

# --- Build frontend ---
echo ""
echo "--- Building shopnow-frontend ---"
cd "${FRONTEND_DIR}"
docker build -t "${HARBOR_HOST}/${HARBOR_PROJECT}/shopnow-frontend:${IMAGE_TAG}" .
echo "--- Pushing shopnow-frontend ---"
docker push "${HARBOR_HOST}/${HARBOR_PROJECT}/shopnow-frontend:${IMAGE_TAG}"

echo ""
echo "============================================"
echo " All images built & pushed successfully!"
echo "============================================"
docker images | grep "${HARBOR_HOST}/${HARBOR_PROJECT}"
