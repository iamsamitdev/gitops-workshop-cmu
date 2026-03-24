# คู่มือ GitOps: App Repo + Manifest Repo สำหรับ Argo CD
# Cross-Repo CI/CD Pipeline — Private Repository Edition

> **ตอบก่อน:** แนวทางข้างต้นถูกต้อง 100% ✅  
> App Repo + Manifest Repo (Separate) = **Best Practice** ของ GitOps  
> สาเหตุ: จำแนก concern ชัดเจน — CI อยู่ใน App Repo, CD อยู่ใน Manifest Repo

---

## ภาพรวม Pipeline

```
App Repo (nodejs-backendapp)         Manifest Repo (nodejs_backendapp_deployment)
┌──────────────────────────┐         ┌─────────────────────────────────────┐
│ src/                     │         │ base/                               │
│ Dockerfile               │         │   deployment.yaml                   │
│ .github/workflows/       │         │   service.yaml                      │
│   build-push.yml         ┼──git──▶ kustomization.yaml (update tag)      │
└──────────────────────────┘  push   │ overlays/                           │
         │                           │   staging/                          │
         │ docker push               │   production/                       │
         ▼                           └────────────┬────────────────────────┘
    GHCR Registry                                 │ auto-sync poll (3 min)
    ghcr.io/iamsamitdev/                          ▼
    nodejs-backendapp:sha               Argo CD → K8s Cluster
```

---

## ข้อกำหนดเบื้องต้น

ก่อนเริ่ม config — เตรียมสิ่งเหล่านี้ให้พร้อม:

| สิ่งที่ต้องการ | วิธีได้มา |
|---|---|
| GitHub PAT (Personal Access Token) | GitHub Settings → Developer Settings → Fine-grained tokens |
| GHCR access (write package) | สร้าง PAT ด้วย `write:packages` permission |
| Argo CD ติดตั้งแล้ว | ดูที่ `gitops/install/argocd-install.md` |
| `kubectl` + `argocd` CLI | ติดตั้งแล้ว |

---

## ส่วนที่ 1: สร้าง GitHub PAT

### 1.1 สร้าง PAT สำหรับ App Repo (CI)

ไปที่ GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens**

**ตั้งค่า:**
- **Token name:** `GITOPS_MANIFEST_TOKEN`
- **Repository access:** เลือกเฉพาะ `nodejs_backendapp_deployment`
- **Permissions:**
  - Contents: `Read and write` ✅
  - Metadata: `Read-only` ✅ (บังคับ)

> **สำคัญ:** copy token ไว้ทันที — จะเห็นแค่ครั้งเดียว!

### 1.2 สร้าง PAT สำหรับ Argo CD (CD)

ใช้ token เดิม หรือสร้างใหม่สำหรับ Manifest Repo:

- **Repository access:** เลือก `nodejs_backendapp_deployment`
- **Permissions:**
  - Contents: `Read-only` ✅ (Argo CD แค่ read)
  - Metadata: `Read-only` ✅

---

## ส่วนที่ 2: ตั้งค่า App Repo (nodejs-backendapp)

### 2.1 เพิ่ม GitHub Secrets ใน App Repo

ไปที่ `nodejs-backendapp` → **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | ค่า | ใช้ทำอะไร |
|---|---|---|
| `GHCR_TOKEN` | PAT ที่มี `write:packages` | push Docker image ไป GHCR |
| `MANIFEST_REPO_TOKEN` | PAT ที่มี `write:contents` ของ manifest repo | update image tag ข้าม repo |

### 2.2 ไฟล์ CI Workflow

```yaml
# 📁 .github/workflows/build-push.yml
# (ใน nodejs-backendapp repo)
#
# Workflow นี้ทำ:
# 1. Build Docker image
# 2. Push ไป GitHub Container Registry (GHCR)
# 3. Update image tag ใน Manifest Repo อัตโนมัติ

name: Build and Push Docker Image

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}   # = iamsamitdev/nodejs-backendapp
  MANIFEST_REPO: iamsamitdev/nodejs_backendapp_deployment

jobs:
  build-and-push:
    name: Build, Push & Update Manifest
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write   # สำหรับ push ไป GHCR

    steps:
      # ── Step 1: Checkout App Repo ──────────────────────────
      - name: Checkout source code
        uses: actions/checkout@v4

      # ── Step 2: Login ไป GHCR ──────────────────────────────
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      # ── Step 3: สร้าง image metadata (tags) ────────────────
      - name: Extract Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            # Tag ด้วย Git SHA (7 ตัวอักษรแรก) — immutable
            type=sha,prefix=,suffix=,format=short
            # Tag ด้วย branch name
            type=ref,event=branch
            # Tag ล่าสุดสำหรับ main branch
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}

      # ── Step 4: Build และ Push Docker Image ────────────────
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # Cache layers เพื่อ speed up
          cache-from: type=gha
          cache-to: type=gha,mode=max

      # ── Step 5: Install kustomize ───────────────────────────
      - name: Install kustomize
        run: |
          curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
          sudo mv kustomize /usr/local/bin/

      # ── Step 6: Update Image Tag ใน Manifest Repo ──────────
      # นี่คือ KEY STEP — push ข้าม repo โดยใช้ MANIFEST_REPO_TOKEN
      - name: Checkout Manifest Repo
        uses: actions/checkout@v4
        with:
          repository: ${{ env.MANIFEST_REPO }}
          token: ${{ secrets.MANIFEST_REPO_TOKEN }}   # ← PAT ที่มีสิทธิ์ write manifest repo
          path: manifest-repo   # checkout เข้า subfolder

      - name: Update image tag in manifest repo
        run: |
          # ดึง short SHA (7 ตัว)
          SHORT_SHA="${{ github.sha }}"
          SHORT_SHA="${SHORT_SHA:0:7}"
          IMAGE="${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${SHORT_SHA}"

          echo "🔄 Updating image tag to: ${IMAGE}"

          # เข้าไปในโฟลเดอร์ manifest repo
          cd manifest-repo

          # ตัวอย่าง: update overlay สำหรับ staging
          cd base
          kustomize edit set image \
            ghcr.io/iamsamitdev/nodejs-backendapp="${IMAGE}"

          echo "📄 Updated kustomization.yaml:"
          cat kustomization.yaml

      - name: Commit and push to Manifest Repo
        run: |
          SHORT_SHA="${{ github.sha }}"
          SHORT_SHA="${SHORT_SHA:0:7}"

          cd manifest-repo
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git add -A

          # ตรวจสอบว่ามีการเปลี่ยนแปลง
          if git diff --cached --quiet; then
            echo "✅ No changes — image tag already up to date"
          else
            git commit -m "deploy: update nodejs-backendapp image to ${SHORT_SHA}

            App Repo: ${{ github.repository }}
            Commit: ${{ github.sha }}
            Workflow: ${{ github.workflow }}"

            git push
            echo "✅ Manifest repo updated — Argo CD will detect OutOfSync"
          fi

      # ── Step 7: Summary ────────────────────────────────────
      - name: Output Summary
        run: |
          SHORT_SHA="${{ github.sha }}"
          echo "## 🚀 Build & Deploy Summary" >> $GITHUB_STEP_SUMMARY
          echo "| ข้อมูล | ค่า |" >> $GITHUB_STEP_SUMMARY
          echo "| --- | --- |" >> $GITHUB_STEP_SUMMARY
          echo "| Image | \`ghcr.io/iamsamitdev/nodejs-backendapp:${SHORT_SHA:0:7}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Manifest Repo | Updated ✅ |" >> $GITHUB_STEP_SUMMARY
          echo "| Argo CD | Will sync within 3 minutes |" >> $GITHUB_STEP_SUMMARY
```

---

## ส่วนที่ 3: ตั้งค่า Manifest Repo (nodejs_backendapp_deployment)

### 3.1 โครงสร้างไฟล์ที่ควรมี

```
nodejs_backendapp_deployment/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml        ← kustomize edit จะแก้ไขไฟล์นี้
├── overlays/
│   ├── staging/
│   │   └── kustomization.yaml
│   └── production/
│       └── kustomization.yaml
└── README.md
```

### 3.2 base/deployment.yaml

```yaml
# 📁 base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-backendapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nodejs-backendapp
  template:
    metadata:
      labels:
        app: nodejs-backendapp
    spec:
      containers:
        - name: nodejs-backendapp
          # ค่า image นี้จะถูก override โดย kustomize images patch
          image: ghcr.io/iamsamitdev/nodejs-backendapp:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: "production"
```

### 3.3 base/service.yaml

```yaml
# 📁 base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-backendapp
spec:
  selector:
    app: nodejs-backendapp
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

### 3.4 base/kustomization.yaml

```yaml
# 📁 base/kustomization.yaml
# ⚠️  ไฟล์นี้จะถูก CI pipeline แก้ไข images.newTag อัตโนมัติ
#     โดยใช้: kustomize edit set image ghcr.io/iamsamitdev/nodejs-backendapp=<sha>

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

# CI pipeline จะ update ค่านี้อัตโนมัติ
images:
  - name: ghcr.io/iamsamitdev/nodejs-backendapp
    newTag: latest   # ← ค่านี้จะถูก CI update เป็น git SHA เช่น a1b2c3d
```

### 3.5 overlays/staging/kustomization.yaml

```yaml
# 📁 overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namePrefix: staging-

commonLabels:
  environment: staging

namespace: staging

patches:
  - target:
      kind: Deployment
      name: nodejs-backendapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 1
```

### 3.6 overlays/production/kustomization.yaml

```yaml
# 📁 overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namePrefix: prod-

commonLabels:
  environment: production

namespace: production

patches:
  - target:
      kind: Deployment
      name: nodejs-backendapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
```

---

## ส่วนที่ 4: ตั้งค่า Argo CD ให้ Access Private Manifest Repo

เนื่องจาก Manifest Repo เป็น **private** — ต้องให้ Argo CD ใช้ PAT เพื่อ clone repo ได้

### 4.1 วิธีที่ 1: ใช้ argocd CLI (เร็วสุด — ทำครั้งแรก)

```bash
# Login Argo CD ก่อน (ต้องรัน port-forward ในอีก terminal)
# kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080 \
  --username admin \
  --password <admin-password> \
  --insecure

# เพิ่ม private manifest repo
argocd repo add https://github.com/iamsamitdev/nodejs_backendapp_deployment.git \
  --username iamsamitdev \
  --password <MANIFEST_REPO_TOKEN>

# ตรวจสอบ
argocd repo list
# ควรเห็น: STATUS=Successful
```

### 4.2 วิธีที่ 2: kubectl apply Secret (declarative — ไม่ผ่าน Git)

```bash
# สร้าง Secret สำหรับ Argo CD repo credentials
# *** อย่า commit ไฟล์นี้ลง Git! ***
kubectl create secret generic argocd-repo-nodejs-deployment \
  --namespace=argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/iamsamitdev/nodejs_backendapp_deployment.git \
  --from-literal=username=iamsamitdev \
  --from-literal=password=<MANIFEST_REPO_TOKEN>

# เพิ่ม label ที่ Argo CD ต้องการ (สำคัญมาก!)
kubectl label secret argocd-repo-nodejs-deployment \
  -n argocd \
  argocd.argoproj.io/secret-type=repository

# ตรวจสอบ
argocd repo list
```

---

## ส่วนที่ 5: สร้าง Argo CD Application

### 5.1 Application สำหรับ Staging

```bash
# สร้าง namespace
kubectl create namespace staging
```

```yaml
# 📁 argo-app-staging.yaml (สร้างไว้ชั่วคราว ไม่ต้อง commit ในไฟล์นี้)
# หรือจะ apply ผ่าน argocd CLI ก็ได้ (ดู 5.3)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-backendapp-staging
  namespace: argocd
spec:
  project: default

  source:
    # Private Manifest Repo — Argo CD ใช้ credentials ที่ตั้งไว้ใน Section 4
    repoURL: https://github.com/iamsamitdev/nodejs_backendapp_deployment.git
    targetRevision: main
    path: overlays/staging      # ชี้ไป overlay สำหรับ staging

  destination:
    server: https://kubernetes.default.svc
    namespace: staging

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f argo-app-staging.yaml
```

### 5.2 Application สำหรับ Production

```yaml
# 📁 argo-app-production.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nodejs-backendapp-production
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/iamsamitdev/nodejs_backendapp_deployment.git
    targetRevision: main
    path: overlays/production    # ชี้ไป overlay สำหรับ production

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    # Production: manual sync เพื่อความปลอดภัย
    syncOptions:
      - CreateNamespace=true
    # automated: ปิดไว้ก่อน — ต้อง sync มือ หรือเปิดทีหลัง
```

```bash
kubectl apply -f argo-app-production.yaml
```

### 5.3 หรือใช้ argocd CLI สร้าง Application โดยตรง

```bash
# Staging — auto-sync
argocd app create nodejs-backendapp-staging \
  --repo https://github.com/iamsamitdev/nodejs_backendapp_deployment.git \
  --path overlays/staging \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace staging \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Production — manual sync
argocd app create nodejs-backendapp-production \
  --repo https://github.com/iamsamitdev/nodejs_backendapp_deployment.git \
  --path overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production
  # ไม่ใส่ --sync-policy = manual sync

# ตรวจสอบ
argocd app list
```

---

## ส่วนที่ 6: GHCR Image Pull Secret

เนื่องจาก GHCR image เป็น private — K8s cluster ต้องมี secret สำหรับ pull image

```bash
# สร้าง imagePullSecret สำหรับ GHCR (ทำทุก namespace)
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=iamsamitdev \
  --docker-password=<GHCR_TOKEN> \
  --docker-email=your@email.com \
  -n staging

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=iamsamitdev \
  --docker-password=<GHCR_TOKEN> \
  --docker-email=your@email.com \
  -n production
```

เพิ่มใน `base/deployment.yaml`:

```yaml
spec:
  template:
    spec:
      # เพิ่มส่วนนี้เพื่อให้ K8s pull image จาก private GHCR ได้
      imagePullSecrets:
        - name: ghcr-secret
      containers:
        - name: nodejs-backendapp
          image: ghcr.io/iamsamitdev/nodejs-backendapp:latest
```

---

## ส่วนที่ 7: End-to-End ทดสอบ

### ขั้นตอนทดสอบครบ pipeline:

```bash
# 1. แก้ code ใน App Repo
# เปิด nodejs-backendapp และแก้ไขอะไรก็ได้ เช่น version number

# 2. Commit & Push
git add .
git commit -m "feat: update api version"
git push origin main

# 3. ดู GitHub Actions รัน (ใน App Repo)
# → Build image → Push GHCR → Update manifest repo

# 4. ดู Manifest Repo — image tag เปลี่ยนอัตโนมัติ
# ไปที่ nodejs_backendapp_deployment → base/kustomization.yaml
# จะเห็น newTag: <new-sha>

# 5. ดู Argo CD
argocd app list
# สถานะจะเปลี่ยนเป็น OutOfSync → Syncing → Synced + Healthy

# 6. ตรวจสอบ
kubectl get pods -n staging
kubectl get pods -n production
argocd app get nodejs-backendapp-staging
```

---

## สรุป: Config ที่ต้องทำทั้งหมด

### App Repo (nodejs-backendapp) ✅

| สิ่งที่ต้องทำ | วิธีทำ |
|---|---|
| เพิ่ม Secret `GHCR_TOKEN` | GitHub Settings → Secrets |
| เพิ่ม Secret `MANIFEST_REPO_TOKEN` | GitHub Settings → Secrets |
| อัปเดต `.github/workflows/build-push.yml` | ตาม Section 2.2 |

### Manifest Repo (nodejs_backendapp_deployment) ✅

| สิ่งที่ต้องทำ | วิธีทำ |
|---|---|
| ตรวจสอบโครงสร้าง base/ + overlays/ | ตาม Section 3.1 |
| ตรวจสอบ `base/kustomization.yaml` มี images section | ตาม Section 3.4 |
| สร้าง `overlays/staging` และ `overlays/production` | ตาม Section 3.5–3.6 |

### Argo CD ✅

| สิ่งที่ต้องทำ | คำสั่ง |
|---|---|
| เพิ่ม private manifest repo credentials | `argocd repo add ... --password <PAT>` |
| สร้าง Application สำหรับ staging | `argocd app create ... overlays/staging` |
| สร้าง Application สำหรับ production | `argocd app create ... overlays/production` |
| สร้าง GHCR pull secret | `kubectl create secret docker-registry ghcr-secret` |

---

## ปัญหาที่พบบ่อยและวิธีแก้

| ปัญหา | สาเหตุ | วิธีแก้ |
|---|---|---|
| CI ส่ง commit แล้ว Argo CD ไม่ sync | รอ polling 3 นาที | ใช้ `argocd app sync <app>` หรือตั้ง webhook |
| `ImagePullBackOff` | ไม่มี imagePullSecret | ดู Section 6 |
| Argo CD เห็น repo แต่ clone ไม่ได้ | PAT expired หรือ permission ผิด | `argocd repo list` → update credentials |
| CI รัน `kustomize edit` แล้วไม่เปลี่ยน | ชื่อ image ใน `kustomization.yaml` ไม่ตรง | ต้องใช้ชื่อ image ตรงๆ เช่น `ghcr.io/iamsamitdev/nodejs-backendapp` |
| Cross-repo push ล้มเหลว | `MANIFEST_REPO_TOKEN` ไม่มีสิทธิ์ write ไปอีก repo | ตรวจสอบ Fine-grained PAT permissions |

---

> **อ้างอิง:**
> - [Argo CD Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
> - [GitHub Fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
> - [GitHub Container Registry (GHCR)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
> - [Kustomize images](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/images/)
