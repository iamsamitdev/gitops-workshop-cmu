# Cheatsheet — คำสั่งที่ใช้บ่อยใน Workshop GitOps with Argo CD

> คำสั่ง kubectl, kind, docker, git ที่ใช้บ่อย — พิมพ์แล้ว bookmark ไว้เลย!

---

## 🐳 Docker

```bash
# Build image
docker build -t <image>:<tag> .
docker build -t my-app:v1.0.0 .

# Tag image
docker tag <image>:<tag> ghcr.io/<user>/<image>:<tag>

# Login GitHub Container Registry
docker login ghcr.io -u <username>

# Push image
docker push ghcr.io/<user>/<image>:<tag>

# Pull image
docker pull ghcr.io/<user>/<image>:<tag>

# Run container
docker run -d -p <host>:<container> <image>:<tag>
docker run -d -p 3000:3000 my-app:v1.0.0

# List containers
docker ps

# Stop / Remove container
docker stop <id>
docker rm <id>

# List images
docker images

# Remove image
docker rmi <image>:<tag>

# View logs
docker logs <container-id>
```

---

## ☸️ kubectl — Basics

```bash
# ดู cluster info
kubectl cluster-info
kubectl get nodes

# ดู context ที่ใช้อยู่
kubectl config current-context
kubectl config get-contexts

# เปลี่ยน context
kubectl config use-context kind-gitops-workshop
```

---

## ☸️ kubectl — Resource Management

```bash
# Apply resource จากไฟล์ / folder / kustomize
kubectl apply -f <file>.yaml
kubectl apply -f <folder>/
kubectl apply -k <kustomize-dir>/

# ลบ resource
kubectl delete -f <file>.yaml
kubectl delete -k <kustomize-dir>/

# ดู rendered YAML โดยไม่ apply
kubectl kustomize <kustomize-dir>/
```

---

## ☸️ kubectl — Inspect Resources

```bash
# Pod
kubectl get pods                          # namespace ปัจจุบัน
kubectl get pods -n <namespace>           # ระบุ namespace
kubectl get pods -A                       # ทุก namespace
kubectl get pods -o wide                  # แสดง IP + Node
kubectl get pods --watch                  # watch mode

# Deployment
kubectl get deployment
kubectl get deploy -n <namespace>

# Service
kubectl get service
kubectl get svc -n <namespace>

# Namespace
kubectl get namespaces
kubectl get ns

# All resources
kubectl get all -n <namespace>

# รายละเอียด resource
kubectl describe pod <pod-name> -n <namespace>
kubectl describe deployment <name> -n <namespace>
kubectl describe svc <name> -n <namespace>
```

---

## ☸️ kubectl — Logs & Debug

```bash
# ดู logs
kubectl logs <pod-name>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -f                # follow mode
kubectl logs <pod-name> --previous        # logs ของ container ที่ crash แล้ว

# เข้าไปใน container
kubectl exec -it <pod-name> -- bash
kubectl exec -it <pod-name> -n <namespace> -- sh

# Port-forward
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## ☸️ kubectl — Namespace

```bash
# สร้าง namespace
kubectl create namespace <name>
kubectl create ns <name>

# ลบ namespace
kubectl delete namespace <name>

# Set default namespace
kubectl config set-context --current --namespace=<name>
```

---

## ☸️ kubectl — Rollout

```bash
# ดูสถานะ rollout
kubectl rollout status deployment/<name>
kubectl rollout status deployment/<name> -n <namespace>

# ดูประวัติ revision
kubectl rollout history deployment/<name>

# Rollback ไป revision ก่อนหน้า
kubectl rollout undo deployment/<name>

# Rollback ไป revision ที่ระบุ
kubectl rollout undo deployment/<name> --to-revision=<number>

# Restart deployment (recreate pods)
kubectl rollout restart deployment/<name>

# เปลี่ยน image โดยตรง (imperative — ไม่แนะนำใน GitOps!)
kubectl set image deployment/<name> <container>=<image>:<tag>
```

---

## 🔧 kind — Kubernetes in Docker

```bash
# สร้าง cluster
kind create cluster --name <name>
kind create cluster --name gitops-workshop --config infra/kind/kind-config.yaml

# ดู cluster ทั้งหมด
kind get clusters

# ดู nodes ใน cluster
kind get nodes --name <cluster-name>

# ลบ cluster
kind delete cluster --name <cluster-name>

# Load image เข้า cluster (ไม่ต้อง push ไป registry)
kind load docker-image <image>:<tag> --name <cluster-name>
```

---

## 📦 Kustomize

```bash
# ดู rendered YAML
kubectl kustomize <dir>/
kustomize build <dir>/

# Apply
kubectl apply -k <dir>/

# ลบ
kubectl delete -k <dir>/

# ตัวอย่าง
kubectl kustomize infra/kustomize/overlays/dev/
kubectl apply -k infra/kustomize/overlays/dev/ -n dev
```

---

## 🔵 Argo CD CLI (Day 2)

```bash
# Login
argocd login localhost:8080 --username admin --password <password> --insecure

# ดู applications
argocd app list

# ดู status
argocd app get <app-name>

# Sync application
argocd app sync <app-name>

# Rollback
argocd app rollback <app-name> <revision>

# ลบ application
argocd app delete <app-name>
```

---

## 🐙 Git — Quick Reference

```bash
# สถานะ
git status
git log --oneline -10

# Add & Commit
git add .
git add <file>
git commit -m "feat: description"

# Push & Pull
git push origin main
git pull origin main

# Branch
git checkout -b <branch>
git switch <branch>

# Revert commit (สำหรับ GitOps rollback)
git revert HEAD          # revert commit ล่าสุด
git revert <commit-sha>  # revert commit ที่ระบุ
git push origin main     # → trigger Argo CD sync
```

---

## 🏷️ Image Tag ที่แนะนำ

```bash
# ดู git SHA (short)
git rev-parse --short HEAD

# Tag image ด้วย git SHA
docker build -t my-app:$(git rev-parse --short HEAD) .

# Tag พร้อม push
SHA=$(git rev-parse --short HEAD)
docker build -t ghcr.io/username/my-app:${SHA} .
docker push ghcr.io/username/my-app:${SHA}
```

---

## 📁 โครงสร้างโปรเจ็กต์ Quick Reference

```
gitops-workshop-cmu/
├── docs/                     # เอกสารทบทวน
│   ├── 00-prerequisites.md   # สิ่งที่ต้องเตรียม
│   ├── 01-gitops-intro.md    # S1+S2 (Day 1)
│   ├── 02-cicd-github-actions.md  # S3+S4 (Day 1)
│   ├── 03-argocd-deep-dive.md    # S5+S6 (Day 2)
│   ├── 04-production-design.md   # S7+S8 (Day 2)
│   └── cheatsheet.md         # ไฟล์นี้
├── app/
│   ├── frontend/Dockerfile   # S3 Frontend image
│   └── backend/Dockerfile    # S3 Backend image
├── infra/
│   ├── kind/kind-config.yaml # S2 Local cluster
│   ├── kubernetes/           # S2+S4 Raw manifests
│   └── kustomize/            # S4+S6 Kustomize
├── gitops/                   # S5+S7+S8 Argo CD
├── .github/workflows/        # S3 CI pipelines
└── scripts/                  # Helper scripts
```
