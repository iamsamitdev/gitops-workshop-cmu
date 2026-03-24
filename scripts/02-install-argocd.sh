#!/bin/bash
# =============================================================
# 02-install-argocd.sh — ติดตั้ง Argo CD + CLI
# Section 5: Argo CD Deep Dive
# =============================================================
# Usage: bash scripts/02-install-argocd.sh
# =============================================================

set -euo pipefail

# ── สีสำหรับ output ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
info()   { echo -e "${BLUE}[i]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}"; }

# ── ตรวจสอบ prerequisites ───────────────────────────────────
header "ตรวจสอบ Prerequisites"

command -v kubectl &>/dev/null || error "kubectl ไม่พบ — กรุณาติดตั้งก่อน"
command -v curl    &>/dev/null || error "curl ไม่พบ — กรุณาติดตั้งก่อน"

KUBECTL_CTX=$(kubectl config current-context 2>/dev/null || echo "none")
info "kubectl context: ${KUBECTL_CTX}"

if [[ "$KUBECTL_CTX" == "none" ]]; then
  error "ไม่ได้ connect กับ cluster — กรุณารัน 'kubectl cluster-info' ก่อน"
fi

# ── ขั้นตอนที่ 1: ติดตั้ง Argo CD ──────────────────────────
header "ขั้นตอนที่ 1: ติดตั้ง Argo CD"

ARGOCD_NAMESPACE="argocd"

# สร้าง namespace
if kubectl get namespace "${ARGOCD_NAMESPACE}" &>/dev/null; then
  warn "Namespace '${ARGOCD_NAMESPACE}' มีอยู่แล้ว — ข้ามการสร้าง"
else
  kubectl create namespace "${ARGOCD_NAMESPACE}"
  log "สร้าง namespace '${ARGOCD_NAMESPACE}' เรียบร้อย"
fi

# ติดตั้ง Argo CD (stable)
info "กำลังติดตั้ง Argo CD (stable release)..."
kubectl apply -n "${ARGOCD_NAMESPACE}" \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log "Apply Argo CD manifests เรียบร้อย"

# ── ขั้นตอนที่ 2: รอ pods พร้อม ─────────────────────────────
header "ขั้นตอนที่ 2: รอ Argo CD Pods พร้อม"

info "รอ argocd-server deployment พร้อม (timeout: 5 นาที)..."
kubectl rollout status deployment/argocd-server \
  -n "${ARGOCD_NAMESPACE}" \
  --timeout=300s

log "argocd-server พร้อมใช้งาน"

# รอ pods ทั้งหมด
info "ตรวจสอบ pods ทั้งหมด..."
kubectl wait pods \
  -n "${ARGOCD_NAMESPACE}" \
  --all \
  --for=condition=Ready \
  --timeout=300s

log "Argo CD pods ทั้งหมดพร้อม"
kubectl get pods -n "${ARGOCD_NAMESPACE}"

# ── ขั้นตอนที่ 3: ดึง Initial Admin Password ────────────────
header "ขั้นตอนที่ 3: Initial Admin Password"

ARGOCD_PASSWORD=$(kubectl -n "${ARGOCD_NAMESPACE}" \
  get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Argo CD Login Information        ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC} URL:      https://localhost:8080       ${GREEN}║${NC}"
echo -e "${GREEN}║${NC} Username: admin                        ${GREEN}║${NC}"
echo -e "${GREEN}║${NC} Password: ${ARGOCD_PASSWORD}${GREEN}${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── ขั้นตอนที่ 4: ติดตั้ง Argo CD CLI ──────────────────────
header "ขั้นตอนที่ 4: ติดตั้ง Argo CD CLI"

if command -v argocd &>/dev/null; then
  ARGOCD_CLI_VERSION=$(argocd version --client --short 2>/dev/null || echo "unknown")
  warn "argocd CLI มีอยู่แล้ว: ${ARGOCD_CLI_VERSION} — ข้ามการติดตั้ง"
else
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  if [[ "$ARCH" == "x86_64" ]]; then ARCH="amd64"; fi
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then ARCH="arm64"; fi

  ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest \
    | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')

  info "กำลังดาวน์โหลด argocd CLI ${ARGOCD_VERSION} สำหรับ ${OS}/${ARCH}..."

  curl -sSL -o /tmp/argocd \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-${OS}-${ARCH}"

  sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
  rm /tmp/argocd

  log "ติดตั้ง argocd CLI เรียบร้อย: $(argocd version --client --short)"
fi

# ── ขั้นตอนที่ 5: วิธีเข้าใช้งาน ────────────────────────────
header "วิธีเข้าใช้งาน Argo CD"

echo ""
info "1. เปิด Port-Forward ในอีก terminal:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
info "2. Login ด้วย CLI:"
echo "   argocd login localhost:8080 --username admin --password '${ARGOCD_PASSWORD}' --insecure"
echo ""
info "3. เปิด browser:"
echo "   https://localhost:8080"
echo ""
log "✅ ติดตั้ง Argo CD เสร็จสมบูรณ์!"
echo ""
info "ขั้นตอนถัดไป: apply Argo CD Applications"
echo "   kubectl apply -f gitops/applications/app-dev.yaml"
