#!/bin/bash
# scripts/03-build-image.sh
# Workshop: GitOps with Argo CD — Day 1, Section 3, Lab 5
# Build Docker image, tag ด้วย git SHA, และ push ไป GHCR

set -euo pipefail

# ─── สี สำหรับ output ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ─── Configuration ────────────────────────────────────────────
# แก้ค่าเหล่านี้ให้ตรงกับ GitHub account ของคุณ
GITHUB_USERNAME="${GITHUB_USERNAME:-REPLACE_YOUR_USERNAME}"
IMAGE_NAME="${IMAGE_NAME:-my-app}"
REGISTRY="ghcr.io"
APP_DIR="${APP_DIR:-app/backend}"   # เปลี่ยนเป็น app/frontend ถ้าต้องการ build frontend

# ─── สร้าง Tag จาก Git SHA ────────────────────────────────────
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
FULL_IMAGE="${REGISTRY}/${GITHUB_USERNAME}/${IMAGE_NAME}"
IMAGE_TAG="${FULL_IMAGE}:${GIT_SHA}"
IMAGE_LATEST="${FULL_IMAGE}:latest"

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GitOps Workshop — Build & Push Image   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Registry  : ${REGISTRY}"
echo -e "  Image     : ${FULL_IMAGE}"
echo -e "  Git SHA   : ${GIT_SHA}"
echo -e "  Tag       : ${IMAGE_TAG}"
echo -e "  App dir   : ${APP_DIR}"
echo ""

# ─── ตรวจสอบ tools ────────────────────────────────────────────
echo -e "${YELLOW}[1/4] ตรวจสอบ dependencies...${NC}"

if ! command -v docker &> /dev/null; then
  echo -e "${RED}❌ Docker ไม่พบ — กรุณาติดตั้งก่อน${NC}"
  exit 1
fi
echo -e "   ${GREEN}✅ Docker$(docker --version)${NC}"

if [[ "${GITHUB_USERNAME}" == "REPLACE_YOUR_USERNAME" ]]; then
  echo -e "${RED}❌ กรุณาตั้งค่า GITHUB_USERNAME ก่อน:${NC}"
  echo -e "   export GITHUB_USERNAME=your-github-username"
  exit 1
fi

echo ""

# ─── Login to GHCR ────────────────────────────────────────────
echo -e "${YELLOW}[2/4] Login ไป GHCR...${NC}"
echo -e "${YELLOW}   ใช้ GitHub Personal Access Token (PAT) ที่มีสิทธิ์ write:packages${NC}"
echo ""
echo "${GITHUB_TOKEN:-}" | docker login "${REGISTRY}" \
  --username "${GITHUB_USERNAME}" \
  --password-stdin 2>/dev/null || \
  docker login "${REGISTRY}" --username "${GITHUB_USERNAME}"

echo ""

# ─── Build Image ──────────────────────────────────────────────
echo -e "${YELLOW}[3/4] Build Docker image...${NC}"
echo -e "   Building from: ${APP_DIR}/Dockerfile"
echo ""

docker build \
  --tag "${IMAGE_TAG}" \
  --tag "${IMAGE_LATEST}" \
  --label "org.opencontainers.image.revision=${GIT_SHA}" \
  --label "org.opencontainers.image.source=https://github.com/${GITHUB_USERNAME}/${IMAGE_NAME}" \
  "${APP_DIR}"

echo ""
echo -e "${GREEN}   ✅ Build เสร็จแล้ว${NC}"
echo ""

# ─── Push Image ───────────────────────────────────────────────
echo -e "${YELLOW}[4/4] Push image ไป GHCR...${NC}"
echo ""

docker push "${IMAGE_TAG}"
docker push "${IMAGE_LATEST}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Push สำเร็จ!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Image ที่ push แล้ว:"
echo -e "  📦 ${IMAGE_TAG}"
echo -e "  📦 ${IMAGE_LATEST}"
echo ""
echo -e "${YELLOW}ขั้นตอนต่อไป (Manual GitOps):${NC}"
echo -e "  1. แก้ image tag ใน infra/kustomize/base/deployment.yaml:"
echo -e "     image: ${IMAGE_TAG}"
echo -e "  2. git commit และ push"
echo -e "  3. kubectl apply -k infra/kustomize/overlays/dev/ -n dev"
echo ""
echo -e "${BLUE}💡 Day 2: Argo CD จะทำขั้นตอน 3 ให้อัตโนมัติ!${NC}"
echo ""
