#!/bin/bash
# =============================================================
# 04-deploy-all.sh — Apply GitOps Layer ทั้งหมด
# Section 8: End-to-End Workshop
# =============================================================
# Usage: bash scripts/04-deploy-all.sh [env]
#   env: dev | staging | production | all (default: dev)
# =============================================================

set -euo pipefail

# ── สีสำหรับ output ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
info()   { echo -e "${BLUE}[i]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════${NC}"; }

# ── รับ argument ─────────────────────────────────────────────
DEPLOY_ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

header "GitOps Workshop — Deploy All (env: ${DEPLOY_ENV})"

# ── ตรวจสอบ prerequisites ───────────────────────────────────
command -v kubectl &>/dev/null || error "kubectl ไม่พบ"
command -v argocd  &>/dev/null || { warn "argocd CLI ไม่พบ — ใช้ kubectl แทน"; ARGOCD_AVAILABLE=false; } || ARGOCD_AVAILABLE=true

KUBECTL_CTX=$(kubectl config current-context 2>/dev/null || echo "none")
info "kubectl context: ${KUBECTL_CTX}"

# ── ฟังก์ชัน deploy ──────────────────────────────────────────
deploy_appproject() {
  header "Apply AppProject"

  info "Apply AppProject สำหรับ dev-team..."
  kubectl apply -f "${ROOT_DIR}/gitops/appproject/project-dev.yaml"
  log "AppProject dev-team พร้อม"

  if [[ "$DEPLOY_ENV" == "production" || "$DEPLOY_ENV" == "all" ]]; then
    info "Apply AppProject สำหรับ production..."
    kubectl apply -f "${ROOT_DIR}/gitops/appproject/project-production.yaml"
    log "AppProject production พร้อม"
  fi
}

deploy_app() {
  local env=$1
  header "Deploy Application: ${env}"

  local app_file="${ROOT_DIR}/gitops/applications/app-${env}.yaml"

  if [[ ! -f "$app_file" ]]; then
    error "ไม่พบไฟล์: $app_file"
  fi

  info "Apply Argo CD Application: ${env}..."
  kubectl apply -f "$app_file"
  log "Application ${env} applied"

  # รอ sync ถ้ามี CLI
  if [[ "${ARGOCD_AVAILABLE:-true}" == "true" ]]; then
    info "รอ Argo CD sync (timeout: 3 นาที)..."
    argocd app wait "my-app-${env}" \
      --sync \
      --health \
      --timeout 180 \
      2>/dev/null || warn "Sync timeout — ตรวจสอบสถานะใน Argo CD UI"
  fi
}

deploy_applicationset() {
  header "Deploy ApplicationSet (Multi-env)"

  info "Apply ApplicationSet..."
  kubectl apply -f "${ROOT_DIR}/gitops/applicationset/multi-env-appset.yaml"
  log "ApplicationSet applied"
}

show_status() {
  header "สถานะหลัง deploy"

  echo ""
  info "Argo CD Applications:"
  kubectl get applications -n argocd 2>/dev/null || warn "ไม่สามารถดู Applications ได้"

  echo ""
  info "Pods ทั้งหมด:"
  case "$DEPLOY_ENV" in
    dev)
      kubectl get pods -n dev 2>/dev/null || warn "Namespace dev ยังไม่มี pods"
      ;;
    staging)
      kubectl get pods -n staging 2>/dev/null || warn "Namespace staging ยังไม่มี pods"
      ;;
    production)
      kubectl get pods -n production 2>/dev/null || warn "Namespace production ยังไม่มี pods"
      ;;
    all)
      for ns in dev staging production; do
        echo -e "\n${BLUE}── Namespace: ${ns} ──${NC}"
        kubectl get pods -n "$ns" 2>/dev/null || warn "Namespace $ns ยังไม่มี pods"
      done
      ;;
  esac
}

# ── Main: Deploy ตาม environment ─────────────────────────────
case "$DEPLOY_ENV" in
  dev)
    deploy_appproject
    deploy_app "dev"
    show_status
    ;;

  staging)
    deploy_appproject
    deploy_app "staging"
    show_status
    ;;

  production)
    warn "⚠️  กำลัง deploy ไป PRODUCTION — ยืนยันหรือไม่?"
    read -r -p "พิมพ์ 'yes' เพื่อยืนยัน: " confirm
    [[ "$confirm" == "yes" ]] || { info "ยกเลิก"; exit 0; }
    deploy_appproject
    deploy_app "production"
    show_status
    ;;

  all)
    info "Deploy ทุก environment (dev → staging → production)"
    deploy_appproject
    deploy_app "dev"
    deploy_app "staging"
    warn "⚠️  กำลัง deploy ไป PRODUCTION — ยืนยันหรือไม่?"
    read -r -p "พิมพ์ 'yes' เพื่อยืนยัน: " confirm
    if [[ "$confirm" == "yes" ]]; then
      deploy_app "production"
    else
      warn "ข้าม production deploy"
    fi
    show_status
    ;;

  appset)
    info "Deploy ด้วย ApplicationSet (สร้างทุก env อัตโนมัติ)"
    deploy_appproject
    deploy_applicationset
    show_status
    ;;

  *)
    error "Environment ไม่ถูกต้อง: ${DEPLOY_ENV}\nใช้: dev | staging | production | all | appset"
    ;;
esac

echo ""
log "✅ Deploy เสร็จสมบูรณ์! environment: ${DEPLOY_ENV}"
echo ""
info "คำสั่งที่ใช้ตรวจสอบ:"
echo "   argocd app list"
echo "   kubectl get pods -n ${DEPLOY_ENV}"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
