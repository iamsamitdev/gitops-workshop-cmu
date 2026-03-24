#!/bin/bash
# scripts/01-setup-kind.sh
# Workshop: GitOps with Argo CD — Day 1, Section 2, Lab 2
# สร้าง kind cluster สำหรับ workshop

set -euo pipefail

# ─── สี สำหรับ output ─────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="gitops-workshop"
KIND_CONFIG="infra/kind/kind-config.yaml"

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GitOps Workshop — Setup Kind Cluster   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─── ตรวจสอบว่าติดตั้ง tools ครบ ─────────────────────────────
echo -e "${YELLOW}[1/4] ตรวจสอบ dependencies...${NC}"

check_tool() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${RED}❌ ไม่พบ $1 — กรุณาติดตั้งก่อน${NC}"
    echo "   ดูวิธีติดตั้ง: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
  fi
  echo -e "   ${GREEN}✅ $1 $(\"$1\" version 2>/dev/null | head -1)${NC}"
}

check_tool docker
check_tool kind
check_tool kubectl

echo ""

# ─── ตรวจสอบว่า cluster มีอยู่แล้วหรือไม่ ─────────────────────
echo -e "${YELLOW}[2/4] ตรวจสอบ cluster ที่มีอยู่...${NC}"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' มีอยู่แล้ว${NC}"
  read -p "   ต้องการลบและสร้างใหม่? (y/N): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}   กำลังลบ cluster เดิม...${NC}"
    kind delete cluster --name "${CLUSTER_NAME}"
    echo -e "${GREEN}   ✅ ลบเสร็จแล้ว${NC}"
  else
    echo -e "${BLUE}   ข้ามการสร้าง — ใช้ cluster เดิม${NC}"
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    exit 0
  fi
fi

echo ""

# ─── สร้าง cluster ────────────────────────────────────────────
echo -e "${YELLOW}[3/4] กำลังสร้าง Kind cluster '${CLUSTER_NAME}'...${NC}"
echo -e "   Config: ${KIND_CONFIG}"
echo ""

kind create cluster \
  --name "${CLUSTER_NAME}" \
  --config "${KIND_CONFIG}"

echo ""

# ─── ตรวจสอบผลลัพธ์ ──────────────────────────────────────────
echo -e "${YELLOW}[4/4] ตรวจสอบ cluster...${NC}"
echo ""

kubectl cluster-info --context "kind-${CLUSTER_NAME}"
echo ""

echo -e "${BLUE}Nodes:${NC}"
kubectl get nodes -o wide
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Cluster พร้อมใช้งานแล้ว!             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "   Cluster name   : ${CLUSTER_NAME}"
echo -e "   Context        : kind-${CLUSTER_NAME}"
echo ""
echo -e "${YELLOW}ขั้นตอนต่อไป:${NC}"
echo -e "   kubectl apply -f infra/kubernetes/namespace.yaml"
echo -e "   kubectl apply -f infra/kubernetes/deployment.yaml"
echo -e "   kubectl apply -f infra/kubernetes/service.yaml"
echo -e "   kubectl get pods -n dev"
echo ""
