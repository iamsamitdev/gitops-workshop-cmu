# Section 3 & 4 — CI/CD Pipeline with GitHub Actions & GitOps Basic Flow

> **Workshop:** GitOps with Argo CD (2026 Edition)  
> **วันที่ 1 | 13:00–16:00**  
> **Section 3:** 13:00–14:15 · Hands-on Lab  
> **Section 4:** 14:30–16:00 · Hands-on Lab

---

## Section 3: CI/CD Pipeline with GitHub Actions

`13:00–14:15 (75 นาที) | Hands-on Lab`

### 3.1 GitHub Actions คืออะไร?

**GitHub Actions** คือ CI/CD platform ของ GitHub ที่ให้เรา automate workflow ได้ตรงบน repository:

```
┌────────────────── GitHub Actions Workflow ─────────────────┐
│                                                            │
│  Trigger (Event)         Job                    Steps      │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │ push to main │──▶│ build-and-  │──▶│ 1. Checkout    │  │
│  │ pull_request │   │ push         │   │ 2. Login GHCR  │  │
│  │ manual       │   │              │   │ 3. Build image │  │
│  └──────────────┘   │ runs-on:     │   │ 4. Push image  │  │
│                     │ ubuntu-latest│   └────────────────┘  │
│                     └──────────────┘                       │
└────────────────────────────────────────────────────────────┘
```

---

### 3.2 GitHub Actions Anatomy — อ่าน YAML ออก

```yaml
# .github/workflows/ci.yml
name: CI Pipeline                    # ชื่อ workflow

on:                                   # Trigger — เมื่อไหร่จะทำงาน
  push:
    branches: [main]                  #   เมื่อ push ไปที่ branch main
  pull_request:
    branches: [main]                  #   เมื่อ PR ไปที่ branch main

jobs:                                 # งานที่ต้องทำ
  build:                              # ชื่อ job
    runs-on: ubuntu-latest            # Runner — ใช้ Ubuntu
    steps:                            # ขั้นตอนของ job
      - uses: actions/checkout@v4     #   Step 1: ดึง code จาก repo
      - name: Build                   #   Step 2: build
        run: echo "Building..."
      - name: Test                    #   Step 3: test
        run: echo "Testing..."
```

**คำศัพท์สำคัญ:**

| คำศัพท์     | คำอธิบาย                                         |
| ----------- | ------------------------------------------------ |
| **Trigger** | Event ที่ทำให้ workflow ทำงาน (push, PR, manual)  |
| **Job**     | กลุ่มของ steps ที่ทำงานบน runner เดียวกัน          |
| **Step**    | แต่ละขั้นตอนภายใน job (run command หรือ use action) |
| **Runner**  | เครื่องที่ใช้รัน job (GitHub-hosted หรือ self-hosted) |
| **Action**  | reusable unit ที่ทำงานเฉพาะทาง (เช่น checkout, login) |

---

### 3.3 Dockerfile Basics

ตัวอย่าง Dockerfile สำหรับ Node.js application (multi-stage build):

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**คำสั่ง Docker ที่ใช้:**

```bash
# Build image
docker build -t my-app:v1.0.0 .

# Tag image สำหรับ registry
docker tag my-app:v1.0.0 ghcr.io/username/my-app:v1.0.0

# Push ไป registry
docker push ghcr.io/username/my-app:v1.0.0

# Pull image จาก registry
docker pull ghcr.io/username/my-app:v1.0.0

# Run container
docker run -d -p 3000:3000 ghcr.io/username/my-app:v1.0.0
```

---

### 3.4 Container Registry — GHCR

**GitHub Container Registry (GHCR)** เป็น container registry ที่ใช้ได้ทันทีกับ GitHub Account:

| Registry   | URL                    | ข้อดี                        |
| ---------- | ---------------------- | ---------------------------- |
| **GHCR**   | `ghcr.io/username/app` | ใช้ได้ทันที, ผูกกับ GitHub     |
| Docker Hub | `docker.io/user/app`   | นิยมมากสุด, มี rate limit     |
| ECR        | `xxx.ecr.region.amazonaws.com` | สำหรับ AWS               |
| GCR/GAR    | `gcr.io/project/app`  | สำหรับ GCP                   |

---

### 3.5 Image Tagging Strategy — ทำไม latest ไม่ควรใช้ใน Production

| Strategy             | ตัวอย่าง             | ข้อดี                         | ข้อเสีย                   |
| -------------------- | -------------------- | ----------------------------- | ------------------------- |
| **latest** ❌         | `my-app:latest`      | สะดวก                         | ไม่รู้ว่า version อะไร, ไม่ reproducible |
| **Git SHA** ✅        | `my-app:a1b2c3d`     | ตรงกับ commit, reproducible   | อ่านยาก                   |
| **Semantic Version** ✅ | `my-app:v1.2.3`     | อ่านง่าย, major/minor/patch   | ต้อง manage version เอง   |
| **Git SHA + SemVer** ✅ | `my-app:v1.2.3-a1b2c3d` | ดีที่สุด — อ่านง่าย + traceable | ยาวหน่อย               |

> **Best Practice:** ใช้ **Git SHA** หรือ **Semantic Version** เสมอ — `latest` ไม่ควรใช้ใน production เพราะ Kubernetes จะไม่ pull image ใหม่ถ้า tag ไม่เปลี่ยน

---

### 🧪 Lab 5: สร้าง GitHub Actions CI Pipeline

**วัตถุประสงค์:** สร้าง CI pipeline ที่ build Docker image แล้ว push ไป GHCR

ดู workflow file ที่: [`.github/workflows/build-push.yml`](../.github/workflows/build-push.yml)

**ขั้นตอนที่ 1:** เตรียม repository บน GitHub

1. Fork หรือสร้าง repo ใหม่บน GitHub จาก repo นี้
2. ตรวจสอบว่า GitHub Actions เปิดใช้งานอยู่ใน Settings → Actions

**ขั้นตอนที่ 2:** ดู workflow ที่เตรียมไว้

```bash
cat .github/workflows/build-push.yml
```

**ขั้นตอนที่ 3:** Push code แล้วดู Actions tab

```bash
git add .
git commit -m "feat: add CI pipeline"
git push origin main
```

**ขั้นตอนที่ 4:** ดู workflow รันใน GitHub Actions
1. ไปที่ GitHub repository → **Actions** tab
2. เลือก workflow `CI - Build and Push Docker Image`
3. ดูแต่ละ step ทำงาน

---

### 🧪 Lab 6: ตรวจสอบ Image ใน GHCR

**ขั้นตอน:**
1. ไปที่ GitHub repository → **Packages** tab
2. ดู image ที่ถูก push พร้อม tag
3. ทดลอง pull มา run บน local:

```bash
docker pull ghcr.io/<username>/<repo>:<sha>
docker run -d -p 3000:3000 ghcr.io/<username>/<repo>:<sha>
```

---

## Section 4: GitOps Basic Flow — Bridge to Argo CD

`14:30–16:00 (90 นาที) | Hands-on Lab`

### 4.1 Git as Single Source of Truth

```
┌─────────────────── GitOps Concept ───────────────────┐
│                                                      │ 
│   "สิ่งที่อยู่ใน Git = สิ่งที่ควรอยู่ใน Cluster"                 │
│                                                       │
│   Git Repo (desired state)   Cluster (actual state)   │
│   ┌────────────────────┐    ┌────────────────────┐    │
│   │ deployment.yaml    │ =? │ Deployment         │    │
│   │   image: v1.2.3    │    │   image: v1.2.3    │    │
│   │   replicas: 3      │    │   replicas: 3      │    │
│   └────────────────────┘    └────────────────────┘    │
│                                                       │
│   ถ้าเท่ากัน  →  ✅ Synced (สถานะปกติ)                   │
│   ถ้าไม่เท่า  →  ⚠️ OutOfSync (ต้อง sync)                 │
└───────────────────────────────────────────────────────┘
```

---

### 4.2 Declarative vs Imperative

| แบบ              | ตัวอย่าง                                    | ข้อดี                              | ข้อเสีย                        |
| ---------------- | ------------------------------------------- | ---------------------------------- | ------------------------------ |
| **Imperative** ❌ | `kubectl run nginx --image=nginx`           | สะดวก, เร็ว                        | ไม่มี record, reproduce ไม่ได้ |
| **Declarative** ✅ | `kubectl apply -f deployment.yaml`         | มี YAML = มี record, reproduce ได้ | ต้องเขียน YAML                 |

> **GitOps Rule:** ทุกอย่างต้องเป็น **Declarative** — ถ้าไม่มีใน Git ก็ไม่ควรอยู่ใน Cluster

---

### 4.3 Manifest Repo — ทำไมต้องแยก App Code กับ Config

```
┌─── App Repo  ───────────────┐    ┌─── Manifest Repo  ────────────┐
│ (Source Code + Dockerfile)  │    │ (Kubernetes YAML configs)     │
│                             │    │                               │
│ src/                        │    │ base/                         │
│   index.js                  │    │   deployment.yaml             │
│   ...                       │    │   service.yaml                │
│ Dockerfile                  │    │   kustomization.yaml          │
│ .github/workflows/ci.yml    │    │ overlays/                     │
│                             │    │   dev/                        │
│ CI: build → push image      │    │   staging/                    │
└─────────────────────────────┘    │   production/                 │
                                   │                               │
                                   │ Argo CD watches this repo!    │
                                   └───────────────────────────────┘
```

**ทำไมต้องแยก?**

| เหตุผล                      | อธิบาย                                                       |
| --------------------------- | ------------------------------------------------------------ |
| **Separation of Concerns**  | dev แก้ code ใน app repo, ops แก้ config ใน manifest repo     |
| **Independent Versioning**  | config เปลี่ยนบ่อยกว่า code (replicas, resources, env vars)  |
| **Security**                | จำกัดสิทธิ์ — ไม่ต้องให้ทุกคนเข้าถึง manifest repo           |
| **Audit Trail**             | commit history ใน manifest repo = deployment history ที่ชัดเจน |

---

### 🧪 Lab 7: สร้าง Manifest Repo (Kustomize Base)

**วัตถุประสงค์:** สร้าง manifest structure สำหรับ GitOps ด้วย Kustomize

ดูไฟล์ที่เตรียมไว้ใน `infra/kustomize/base/`:

```bash
# ดูโครงสร้าง
ls infra/kustomize/base/

# Apply base manifests ใน dev namespace
kubectl apply -k infra/kustomize/base/ -n dev

# ดูผลลัพธ์
kubectl get all -n dev
```

ดูไฟล์ที่เกี่ยวข้อง:
- [`infra/kustomize/base/deployment.yaml`](../infra/kustomize/base/deployment.yaml)
- [`infra/kustomize/base/service.yaml`](../infra/kustomize/base/service.yaml)
- [`infra/kustomize/base/kustomization.yaml`](../infra/kustomize/base/kustomization.yaml)

---

### 🧪 Lab 8: Manual GitOps — แก้ Image Tag แล้ว Apply ด้วยมือ

**วัตถุประสงค์:** ทำ GitOps ด้วยมือ (manual) เพื่อเห็นปัญหาถ้าไม่มี automation

**ขั้นตอนที่ 1:** แก้ image tag ใน `infra/kustomize/base/deployment.yaml`

```yaml
# เปลี่ยนจาก
image: ghcr.io/<username>/my-app:latest
# เป็น
image: ghcr.io/<username>/my-app:<new-sha>
```

**ขั้นตอนที่ 2:** Commit & push

```bash
git add infra/kustomize/base/deployment.yaml
git commit -m "deploy: update image to <new-sha>"
git push origin main
```

**ขั้นตอนที่ 3:** Apply ด้วยมือ

```bash
kubectl apply -k infra/kustomize/base/ -n dev
kubectl get pods -n dev
kubectl rollout status deployment/my-app -n dev
```

**ขั้นตอนที่ 4:** สังเกต state เปลี่ยน

```bash
kubectl get pods -w -n dev  # watch pods เปลี่ยน
```

---

### 🧪 Lab 9: ตั้งคำถาม — ทำไมต้อง Argo CD?

**คำถามให้คิด:**
- ถ้าต้องทำ Lab 8 ทุกครั้งที่มี commit ใหม่ มีปัญหาอะไร?
- ถ้ามีคน `kubectl apply` version ผิด จะรู้ได้อย่างไร?
- ถ้ามีคนลบ Deployment ตรงจาก cluster ใครจะฟื้นให้?
- ถ้ามี 10 environments ต้อง apply ทุก env ทีละ command?

> **คำตอบ:** Argo CD จะทำ kubectl apply ให้อัตโนมัติ ตรวจจับ drift ได้ และ self-heal เมื่อมีคนแก้ cluster ตรง — ซึ่งเราจะเรียนกันใน Day 2!

---

### 4.4 End-to-End Flow — สิ่งที่เราทำได้ใน Day 1

```
┌──────────────────── Day 1 End-to-End Flow ────────────────────┐
│                                                               │
│  1. Code         2. GitHub Actions      3. GHCR               │
│  ┌────────┐     ┌────────────────┐     ┌──────────────┐       │
│  │ git    │────▶│ build image    │────▶│ push image  │       │
│  │ push   │     │ tag: git SHA   │     │ ghcr.io/...  │       │
│  └────────┘     └────────────────┘     └──────┬───────┘       │
│                                               │               │
│  4. Update Manifest   5. kubectl apply (Manual)│              │
│  ┌────────────────┐   ┌────────────────┐       │              │
│  │ แก้ image tag   │─▶│ kubectl apply  │◀──────┘              │
│  │ ใน manifest    │   │ -k . (ด้วยมือ)   │                      │
│  │ repo + commit  │   └───────┬────────┘                      │
│  └────────────────┘           │                               │
│                               ▼                               │
│                        ┌──────────────┐                       │
│                        │  Kubernetes  │                       │
│                        │  Cluster     │                       │
│                        └──────────────┘                       │
│                                                               │
│  Day 2: Argo CD จะแทน step 5 (kubectl apply ด้วยมือ)            │
│         ให้เป็นอัตโนมัติ + self-heal + drift detection!            │
└───────────────────────────────────────────────────────────────┘
```

---

### สรุป Day 1

ในวันแรกเราได้เรียนรู้พื้นฐานสำคัญสำหรับ GitOps pipeline:

**Section 1: DevOps → GitOps**

- ✅ เข้าใจ Pain Point ของ Traditional CI/CD (Push-based)
- ✅ GitOps 4 หลักการ: Declarative, Versioned, Automated, Continuously Reconciled
- ✅ Push-based vs Pull-based — ทำไม Pull-based ปลอดภัยกว่า
- ✅ Argo CD overview — CNCF Graduated Project

**Section 2: Kubernetes Fundamentals**

- ✅ Core Objects: Pod, Deployment, Service, Namespace
- ✅ kubectl essentials: apply, get, describe, logs, rollout
- ✅ YAML Anatomy: apiVersion, kind, metadata, spec
- ✅ Namespace strategy: dev / staging / production

**Section 3: CI/CD Pipeline with GitHub Actions**

- ✅ GitHub Actions anatomy: trigger, job, step, runner
- ✅ Build Docker image และ push ไป GHCR
- ✅ Image tagging strategy: Git SHA vs Semantic Version (ห้ามใช้ latest!)

**Section 4: GitOps Basic Flow**

- ✅ Git as Single Source of Truth
- ✅ Declarative vs Imperative — ทำไม declarative ดีกว่า
- ✅ Manifest Repo: แยก app code กับ config
- ✅ Manual GitOps: เห็นปัญหาถ้าไม่มี automation → เข้าใจว่าทำไมต้อง Argo CD

> **Day 2:** [Argo CD Deep Dive + Kustomize + Production Design → End-to-End](03-argocd-deep-dive.md)
