## Workshop: GitOps with Argo CD — Day 2

## Argo CD Deep Dive, Kustomize, Production Design & End-to-End

### Download Training Document

[Click here to download the training document](https://bit.ly/gitops-cmu)

---

### บทนำ Day 2

วันที่ 2 เป็น **หัวใจของหลักสูตร** — ต่อยอดจาก manifest repo ที่สร้างใน Day 1 โดยนำ **Argo CD** มาจัดการ deployment อัตโนมัติ ผู้เรียนจะได้ลงมือติดตั้ง Argo CD, ทดลอง Auto-Sync, Self-Heal, Drift Detection, ใช้ Kustomize จัดการ multi-environment, ออกแบบ RBAC + Secrets สำหรับ production และทำ **End-to-End Workshop** pipeline สมบูรณ์ด้วยตัวเอง

---

### ตารางเวลา — วันที่ 2: Argo CD + Production

| Section | เวลา        | หัวข้อ                                          | รูปแบบ   | หมายเหตุ                                |
| ------- | ----------- | ----------------------------------------------- | -------- | --------------------------------------- |
| S5      | 09:00–10:30 | Argo CD Deep Dive — sync, self-heal, rollback    | Lab      | 90 นาที — ต่อจาก manifest repo Day 1     |
| —       | 10:30–10:45 | พักเบรก                                         | —        |                                         |
| S6      | 10:45–12:00 | Kustomize Multi-env Lab + Helm Overview          | Lab      | 75 นาที — Kustomize เน้น / Helm demo     |
| —       | 12:00–13:00 | พักรับประทานอาหาร                               | —        |                                         |
| S7      | 13:00–14:15 | Production Design — Git Structure, RBAC, Secrets | Lab      | 75 นาที — real-world design              |
| —       | 14:15–14:30 | พักเบรก                                         | —        |                                         |
| S8      | 14:30–16:00 | Best Practices + Final End-to-End Workshop       | Workshop | 90 นาที — ผู้เรียนทำ pipeline ด้วยตัวเอง |

---

## Section 5: Argo CD Deep Dive

`09:00–10:30 (90 นาที) | Hands-on Lab`

### 5.1 ติดตั้ง Argo CD บน Kubernetes

**ขั้นตอนที่ 1:** สร้าง namespace และติดตั้ง Argo CD

```bash
# สร้าง namespace สำหรับ Argo CD
kubectl create namespace argocd

# ติดตั้ง Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# รอจน pod ทั้งหมดพร้อม
kubectl get pods -n argocd -w
```

**ขั้นตอนที่ 2:** เข้าถึง Argo CD UI

```bash
# Port-forward เพื่อเข้า UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# ดู initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

- เปิด browser: `https://localhost:8080`
- Login: username = `admin`, password = (จากคำสั่งด้านบน)

**ขั้นตอนที่ 3:** ติดตั้ง Argo CD CLI

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login ผ่าน CLI
argocd login localhost:8080 --username admin --password <password> --insecure
```

### 5.2 สร้าง Application — Declarative YAML

ต่อจาก manifest repo ที่ทำใน Day 1 โดยตรง:

```yaml
# argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/<username>/my-app-manifests.git
    targetRevision: main
    path: .                    # path ที่เก็บ manifests

  destination:
    server: https://kubernetes.default.svc
    namespace: default

  syncPolicy:
    automated:                 # Auto-Sync: เปิด/ปิดได้
      prune: true              # ลบ resource ที่ไม่มีใน Git
      selfHeal: true           # แก้ไขเมื่อมีคนเปลี่ยน cluster ตรง
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f argocd-app.yaml
```

> **สังเกต:** Argo CD Application เองก็เป็น Kubernetes resource (CRD) — สร้างได้ด้วย `kubectl apply` เหมือน resource อื่น

### 5.3 Sync Lifecycle — เข้าใจสถานะของ Application

```
┌───────────────────── Argo CD Sync Lifecycle ─────────────────────┐
│                                                                   │
│   ┌──────────┐    ┌─────────────┐    ┌──────────┐    ┌─────────┐ │
│   │  Synced  │───▶│ OutOfSync   │───▶│ Syncing  │───▶│ Healthy │ │
│   │  ✅      │    │  ⚠️         │    │  🔄      │    │  💚     │ │
│   └──────────┘    └─────────────┘    └──────────┘    └─────────┘ │
│        ▲                                                  │      │
│        └──────────────────────────────────────────────────┘      │
│                                                                   │
│   Synced     = Git state == Cluster state                        │
│   OutOfSync  = Git state ≠ Cluster state (ต้อง sync)             │
│   Syncing    = กำลัง apply changes                                │
│   Healthy    = ทุก resource พร้อมใช้งาน                           │
│   Degraded   = บาง resource มีปัญหา                               │
│   Missing    = resource ยังไม่ถูกสร้าง                             │
└───────────────────────────────────────────────────────────────────┘
```

| สถานะ         | ความหมาย                                    | สี    |
| ------------- | ------------------------------------------- | ----- |
| **Synced**    | Git state = Cluster state                   | 🟢 เขียว |
| **OutOfSync** | Git state ≠ Cluster state                   | 🟡 เหลือง |
| **Unknown**   | ไม่สามารถตรวจสอบได้                          | ⚪ เทา   |
| **Healthy**   | ทุก resource ทำงานปกติ                       | 💚 เขียว |
| **Degraded**  | บาง resource มีปัญหา                         | 🔴 แดง  |
| **Progressing** | กำลัง rollout / deploy อยู่                 | 🔵 น้ำเงิน |

### 5.4 Auto-Sync & Self-Heal

**Auto-Sync:** Argo CD จะ sync อัตโนมัติเมื่อตรวจพบว่า Git เปลี่ยน

```yaml
syncPolicy:
  automated:
    prune: true       # ลบ resource ที่ไม่มีใน Git
    selfHeal: true    # ฟื้นคืนเมื่อมีคนแก้ cluster ตรง
```

| ตัวเลือก      | คำอธิบาย                                                    |
| ------------- | ----------------------------------------------------------- |
| **automated** | เปิด auto-sync — ไม่ต้องกด sync มือ                         |
| **prune**     | ถ้า resource ถูกลบออกจาก Git → ลบออกจาก cluster ด้วย        |
| **selfHeal**  | ถ้ามีคนแก้ cluster โดยตรง → Argo CD revert กลับเป็นตาม Git   |

**Self-Heal ทำงานอย่างไร:**

```
1. คุณตั้ง replicas: 3 ใน Git
2. มีคนรัน kubectl scale --replicas=5 ตรงที่ cluster
3. Argo CD ตรวจพบ: cluster (5) ≠ Git (3) → OutOfSync
4. Self-Heal: Argo CD apply replicas: 3 กลับ → Synced
5. ใช้เวลาไม่เกิน 3 นาที (default sync interval)
```

### 5.5 Drift Detection

**Drift** = สถานะใน cluster ไม่ตรงกับที่กำหนดใน Git

```
┌─── Git Repo ───┐        ┌─── Cluster ───┐
│ replicas: 3     │   ≠    │ replicas: 5    │  ← มีคนแก้ตรง!
│ image: v1.2.3   │   =    │ image: v1.2.3  │
└─────────────────┘        └────────────────┘
         │                         │
         └────── Argo CD ──────────┘
               "OutOfSync! ⚠️"
```

> **สำคัญ:** Argo CD สแกน cluster ทุก **3 นาที** (default) — ถ้าใครแก้อะไรใน cluster โดยตรง Argo CD จะรู้ทันทีในรอบถัดไป

### 5.6 Rollback ด้วย Argo CD

```bash
# ดูประวัติ revision ของ application
argocd app history my-app

# Rollback ไป revision ก่อนหน้า
argocd app rollback my-app <revision-number>

# หรือ rollback ผ่าน Git (แนะนำ)
git revert HEAD
git push origin main
# → Argo CD จะ detect OutOfSync แล้ว sync กลับอัตโนมัติ
```

**วิธี Rollback 2 แบบ:**

| วิธี                    | คำสั่ง                          | ข้อดี                         | ข้อเสีย                    |
| ----------------------- | ------------------------------- | ----------------------------- | -------------------------- |
| **argocd rollback** 🔧  | `argocd app rollback my-app N`  | เร็ว, ง่าย                    | Git ยังเป็น version ใหม่    |
| **git revert** ✅ (แนะนำ) | `git revert HEAD && git push` | Git history สะอาด, traceable | ช้ากว่าเล็กน้อย             |

> **Best Practice:** ใช้ **git revert** เสมอ — เพราะ Git คือ single source of truth ถ้า rollback แค่ใน Argo CD แต่ Git ยังเป็น version ใหม่ จะเกิด OutOfSync

### 5.7 Sync Waves & Resource Hooks

**Sync Waves** = ลำดับในการ deploy resource

```yaml
# deploy namespace ก่อน (wave 0)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"

# แล้วค่อย deploy ConfigMap (wave 1)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"

# สุดท้ายค่อย deploy Deployment (wave 2)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
```

**Resource Hooks** = ทำงานก่อน/หลัง sync

```yaml
# PreSync Job: migrate database ก่อน deploy
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/hook: PreSync           # ทำก่อน sync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: my-app:latest
          command: ["npm", "run", "migrate"]
      restartPolicy: Never
```

| Hook         | เมื่อไหร่                 | ตัวอย่างการใช้งาน        |
| ------------ | ------------------------- | ------------------------ |
| **PreSync**  | ก่อน sync                 | Database migration       |
| **Sync**     | ระหว่าง sync              | ส่วนใหญ่ไม่ใช้            |
| **PostSync** | หลัง sync สำเร็จ          | ส่ง notification, run test |
| **SyncFail** | เมื่อ sync ล้มเหลว        | ส่ง alert                 |

### 🧪 Lab 9: ติดตั้ง Argo CD & Connect Manifest Repo

**วัตถุประสงค์:** ติดตั้ง Argo CD และ connect กับ manifest repo จาก Day 1

**ขั้นตอน:**
1. ติดตั้ง Argo CD ตาม Section 5.1
2. สร้าง Application YAML ตาม Section 5.2
3. ดู Argo CD UI — เห็น app sync ครั้งแรก
4. ตรวจสอบ: app status = Synced + Healthy

```bash
# ตรวจสอบสถานะ
argocd app get my-app
argocd app list
```

### 🧪 Lab 10: Self-Heal — ลบ Deployment แล้ว Argo CD ฟื้นคืน

**วัตถุประสงค์:** ทดลอง Self-Heal — ลบ Deployment ออกจาก cluster โดยตรง แล้วดู Argo CD ฟื้นคืนอัตโนมัติ

```bash
# ลบ Deployment โดยตรง (อย่าทำใน production!)
kubectl delete deployment my-app

# ดู Argo CD UI — สถานะเปลี่ยนเป็น OutOfSync → Missing
# รอ 1-3 นาที — Argo CD Self-Heal สร้าง Deployment กลับมาใหม่

# ยืนยัน
kubectl get deployment my-app
argocd app get my-app
```

> **สังเกต:** Argo CD สร้าง Deployment กลับมาเองโดยไม่ต้องมีคนทำอะไร — นี่คือพลังของ Self-Heal!

### 🧪 Lab 11: Rollback ด้วย Argo CD

**วัตถุประสงค์:** ทดลอง rollback ไป version ก่อนหน้า

```bash
# ดูประวัติ revision
argocd app history my-app

# Rollback ไป revision ก่อนหน้า
argocd app rollback my-app 1

# ยืนยัน
argocd app get my-app
kubectl get pods
```

---

## Section 6: Kustomize Multi-environment + Helm Overview

`10:45–12:00 (75 นาที) | Hands-on Lab`

### 6.1 Kustomize คืออะไร?

**Kustomize** คือเครื่องมือจัดการ Kubernetes YAML โดยใช้ **overlay pattern** — มี base config กลาง แล้ว patch ค่าที่ต่างกันสำหรับแต่ละ environment:

```
┌──────────────────── Kustomize Structure ────────────────────┐
│                                                              │
│  base/                    (config กลาง — ใช้ร่วมกัน)        │
│  ├── deployment.yaml       replicas: 1, image: my-app        │
│  ├── service.yaml          port: 80                          │
│  └── kustomization.yaml    resources: [deployment, service]  │
│                                                              │
│  overlays/                                                   │
│  ├── dev/                  (dev environment)                 │
│  │   └── kustomization.yaml  replicas: 1, namePrefix: dev-  │
│  ├── staging/              (staging environment)             │
│  │   └── kustomization.yaml  replicas: 2                     │
│  └── prod/                 (production environment)          │
│      └── kustomization.yaml  replicas: 3, namePrefix: prod- │
│                                                              │
│  ผลลัพธ์: แต่ละ env ได้ YAML ที่ต่างกันโดยไม่ต้อง copy ทั้งไฟล์ │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 Base — Config กลาง

```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: ghcr.io/username/my-app:latest
          ports:
            - containerPort: 3000
```

```yaml
# base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 3000
```

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

### 6.3 Overlays — Config เฉพาะ Environment

**Dev Overlay:**

```yaml
# overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namePrefix: dev-
commonLabels:
  environment: dev
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |
      - op: replace
        path: /spec/replicas
        value: 1
images:
  - name: ghcr.io/username/my-app
    newTag: dev-latest
```

**Production Overlay:**

```yaml
# overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namePrefix: prod-
commonLabels:
  environment: production
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |
      - op: replace
        path: /spec/replicas
        value: 3
images:
  - name: ghcr.io/username/my-app
    newTag: v1.2.3
```

### 6.4 เทคนิค Kustomize ที่ใช้บ่อย

| เทคนิค              | คำอธิบาย                                          | ตัวอย่าง                           |
| -------------------- | ------------------------------------------------- | ---------------------------------- |
| **images**           | เปลี่ยน image tag โดยไม่แก้ base                   | `newTag: v1.2.3`                  |
| **replicas**         | เปลี่ยนจำนวน replicas                              | `- name: my-app` `count: 3`      |
| **namePrefix**       | เพิ่ม prefix ให้ชื่อ resource                       | `namePrefix: prod-`              |
| **commonLabels**     | เพิ่ม label ให้ทุก resource                         | `environment: production`        |
| **patches**          | แก้ไขค่าเฉพาะจุด (JSON patch)                      | replace replicas, add env vars   |
| **configMapGenerator** | สร้าง ConfigMap จาก file หรือ literal             | `configMapGenerator:` + `literals` |

### 6.5 images patch — CI/CD ต้องการสิ่งนี้

ในทางปฏิบัติ CI pipeline จะ update image tag ใน overlay โดยใช้ `kustomize edit`:

```bash
# CI pipeline update image tag ใน overlay
cd overlays/prod
kustomize edit set image ghcr.io/username/my-app:v1.2.4

# ดูผลลัพธ์
kustomize build overlays/prod
```

> **Best Practice:** CI pipeline ไม่ควรแก้ YAML ตรง — ใช้ `kustomize edit set image` แทน เพื่อลดโอกาสผิดพลาด

### 6.6 Kustomize ร่วมกับ Argo CD

Argo CD สามารถ render Kustomize ได้โดยตรง — ไม่ต้องติดตั้ง Kustomize CLI แยก:

```yaml
# argocd-app-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/username/my-app-manifests.git
    targetRevision: main
    path: overlays/dev         # ← ชี้ไปที่ overlay ของ dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 6.7 Helm — Overview

**Helm** คือ package manager สำหรับ Kubernetes — เปรียบเหมือน `apt` หรือ `npm` แต่สำหรับ K8s:

| ลักษณะ         | Kustomize                         | Helm                                  |
| -------------- | --------------------------------- | ------------------------------------- |
| **แนวคิด**     | Overlay + Patch YAML              | Template + Values                     |
| **ไฟล์หลัก**   | `kustomization.yaml`              | `Chart.yaml` + `values.yaml`         |
| **ความซับซ้อน** | ง่าย — อ่าน YAML ออกก็ใช้ได้       | ปานกลาง — ต้องรู้ Go template         |
| **เหมาะกับ**   | แก้ไข config เฉพาะ env             | แจกจ่าย app เป็น package              |
| **Argo CD**    | รองรับ native                     | รองรับ native                         |

**เมื่อไหร่ใช้ Kustomize vs Helm?**

| สถานการณ์                               | เลือก                  |
| --------------------------------------- | ---------------------- |
| ทีมเขียน manifests เอง + ต้องการ multi-env | **Kustomize** ✅        |
| ใช้ open-source app (Nginx, Prometheus)  | **Helm** ✅ (ใช้ chart) |
| ต้องการ package + distribute app         | **Helm** ✅             |
| ต้องการความง่ายสูงสุด                    | **Kustomize** ✅        |

### 🧪 Lab 12: ปรับ Manifest Repo เป็น Kustomize Structure

**วัตถุประสงค์:** ปรับ manifest repo จาก Day 1 ให้เป็น Kustomize structure

**ขั้นตอนที่ 1:** สร้างโครงสร้าง base + overlays

```bash
mkdir -p base overlays/dev overlays/prod
mv deployment.yaml service.yaml base/
```

**ขั้นตอนที่ 2:** สร้าง `base/kustomization.yaml`, `overlays/dev/kustomization.yaml`, `overlays/prod/kustomization.yaml` ตาม Section 6.2–6.3

**ขั้นตอนที่ 3:** ทดสอบ

```bash
# Preview YAML ที่ Kustomize จะ generate
kustomize build overlays/dev
kustomize build overlays/prod
```

### 🧪 Lab 13: ทดลองเปลี่ยนค่าแต่ละ Environment

**วัตถุประสงค์:** เห็น Argo CD render Kustomize ต่างกันตาม environment

- dev: `replicas=1`
- prod: `replicas=3`
- สังเกตจาก Argo CD UI ว่า dev app กับ prod app มีค่าต่างกัน

```bash
# Commit & push
git add .
git commit -m "refactor: restructure to Kustomize base/overlays"
git push origin main

# สร้าง Argo CD Application สำหรับ dev และ prod
kubectl apply -f argocd-app-dev.yaml
kubectl apply -f argocd-app-prod.yaml

# ตรวจสอบ
argocd app list
kubectl get pods -n dev
kubectl get pods -n production
```

### 🎬 Demo: Helm — Deploy App จาก Public Chart ผ่าน Argo CD

วิทยากร demo ผู้เรียนดู:

```yaml
# argocd-helm-demo.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-helm
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 18.2.4
    helm:
      values: |
        replicaCount: 2
        service:
          type: NodePort
          nodePorts:
            http: 30090
  destination:
    server: https://kubernetes.default.svc
    namespace: helm-demo
  syncPolicy:
    automated:
      prune: true
    syncOptions:
      - CreateNamespace=true
```

---

## Section 7: Production Design — Git Structure, RBAC & Secrets

`13:00–14:15 (75 นาที) | Hands-on Lab`

### 7.1 Git Structure Strategy — Mono-repo vs Multi-repo

| Strategy       | คำอธิบาย                         | ข้อดี                              | ข้อเสีย                         |
| -------------- | -------------------------------- | ---------------------------------- | -------------------------------- |
| **Mono-repo**  | ทุก app อยู่ใน repo เดียว         | ง่ายต่อการจัดการ, CI/CD ที่เดียว    | repo ใหญ่, permission ลำบาก      |
| **Multi-repo** | แต่ละ app มี repo แยก            | permission ชัดเจน, แยกทีมได้        | จัดการหลาย repo, sync ยาก        |

**Pattern ที่ใช้จริง:**

```
# Mono-repo Pattern (เหมาะกับทีมเล็ก-กลาง)
gitops-manifests/
├── apps/
│   ├── frontend/
│   │   ├── base/
│   │   └── overlays/
│   ├── backend/
│   │   ├── base/
│   │   └── overlays/
│   └── worker/
│       ├── base/
│       └── overlays/
├── infrastructure/
│   ├── argocd/
│   ├── monitoring/
│   └── ingress/
└── README.md

# Multi-repo Pattern (เหมาะกับทีมใหญ่)
frontend-manifests/     ← Frontend team
backend-manifests/      ← Backend team
data-manifests/         ← Data team
infra-manifests/        ← Platform team
```

### 7.2 Image Tagging ใน Production

| Strategy         | ตัวอย่าง              | Rollback ทำอย่างไร                    |
| ---------------- | --------------------- | ------------------------------------- |
| **Git SHA**      | `my-app:a1b2c3d`     | `git revert` → CI build ใหม่ → tag ใหม่ |
| **SemVer**       | `my-app:v1.2.3`      | แก้ overlay → `newTag: v1.2.2`        |
| **Environment**  | `my-app:staging`      | ❌ ไม่แนะนำ — mutable tag             |

> **Best Practice:** ใช้ **immutable tag** เสมอ (Git SHA หรือ SemVer) — ห้ามใช้ `latest` หรือ environment tag ใน production

### 7.3 AppProject & RBAC — Multi-tenancy

**AppProject** = ขอบเขตสำหรับแต่ละทีม — กำหนดว่าทีมไหนเข้าถึง repo ไหน, deploy ไป namespace ไหน

```yaml
# appproject-dev-team.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: dev-team
  namespace: argocd
spec:
  description: "Dev Team project"

  # Repo ที่อนุญาต
  sourceRepos:
    - https://github.com/org/dev-manifests.git

  # Destination ที่อนุญาต
  destinations:
    - namespace: dev
      server: https://kubernetes.default.svc
    - namespace: staging
      server: https://kubernetes.default.svc

  # Resource ที่อนุญาตให้สร้าง
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace

  # Resource ที่ห้ามสร้าง
  namespaceResourceBlacklist:
    - group: ""
      kind: ResourceQuota
    - group: ""
      kind: LimitRange
```

**RBAC Configuration:**

```csv
# argocd-rbac-cm ConfigMap
p, role:dev-team, applications, get, dev-team/*, allow
p, role:dev-team, applications, sync, dev-team/*, allow
p, role:dev-team, applications, create, dev-team/*, allow
p, role:dev-team, applications, delete, dev-team/*, deny

g, dev-group, role:dev-team
```

| RBAC Rule                    | ความหมาย                                        |
| ---------------------------- | ------------------------------------------------ |
| `applications, get, allow`   | ดูรายการ app ได้                                  |
| `applications, sync, allow`  | กด sync ได้                                      |
| `applications, create, allow` | สร้าง app ใหม่ได้                                 |
| `applications, delete, deny`  | ❌ ลบ app ไม่ได้ — ต้องให้ admin ทำ               |

### 7.4 Sealed Secrets — เก็บ Secret ใน Git อย่างปลอดภัย

**ปัญหา:** Kubernetes Secret เป็นแค่ base64 — ถ้า commit ใน Git ใครเปิดก็เห็น

**Sealed Secrets แก้ปัญหา:** encrypt secret ด้วย public key → commit ใน Git ได้ → Sealed Secrets controller ใน cluster decrypt ให้

```
┌─────────────── Sealed Secrets Flow ───────────────┐
│                                                     │
│  1. สร้าง Secret             2. Encrypt             │
│  ┌──────────────────┐       ┌──────────────────┐    │
│  │ apiVersion: v1   │──────▶│ apiVersion:      │    │
│  │ kind: Secret     │ kubeseal │ bitnami.com/v1 │   │
│  │ data:            │       │ kind: SealedSecret│    │
│  │   password: xxx  │       │ spec:             │    │
│  └──────────────────┘       │   encryptedData:  │    │
│    (ห้าม commit!)           │     password: ... │    │
│                             └────────┬─────────┘    │
│                                      │ ✅ commit!   │
│  3. Git Repo        4. Argo CD       │              │
│  ┌──────────┐      ┌────────────┐    │              │
│  │ sealed-  │◀─────│ apply      │◀───┘              │
│  │ secret.  │      │ sealed-    │                    │
│  │ yaml     │      │ secret     │                    │
│  └──────────┘      └─────┬──────┘                    │
│                          │                           │
│  5. Sealed Secrets Controller decrypt               │
│  ┌──────────────────────────────┐                    │
│  │ SealedSecret → Secret        │                    │
│  │ Pod สามารถอ่าน Secret ได้    │                    │
│  └──────────────────────────────┘                    │
└─────────────────────────────────────────────────────┘
```

**ขั้นตอน:**

```bash
# ติดตั้ง Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.0/controller.yaml

# ติดตั้ง kubeseal CLI
brew install kubeseal   # macOS

# สร้าง Secret ปกติ
kubectl create secret generic my-secret \
  --from-literal=DB_PASSWORD=supersecret123 \
  --dry-run=client -o yaml > my-secret.yaml

# Encrypt ด้วย kubeseal
kubeseal --format yaml < my-secret.yaml > sealed-secret.yaml

# Commit sealed-secret.yaml ใน Git (ปลอดภัย!)
git add sealed-secret.yaml
git commit -m "feat: add sealed database secret"
git push origin main
```

### 7.5 Anti-patterns ที่ควรหลีกเลี่ยง

| Anti-pattern ❌                         | ทำไมถึงเป็นปัญหา                            | Best Practice ✅                       |
| --------------------------------------- | ------------------------------------------- | -------------------------------------- |
| เก็บ Secret ใน Git (plain text)          | ใครเข้า Git ก็เห็น password                  | ใช้ Sealed Secrets หรือ Vault           |
| ใช้ `latest` tag                        | ไม่รู้ว่า version อะไร, ไม่ reproducible      | ใช้ Git SHA หรือ SemVer                |
| แก้ cluster โดยตรง (`kubectl edit`)      | Drift — Argo CD จะ revert กลับ              | แก้ที่ Git เสมอ                        |
| ไม่มี AppProject / RBAC                 | ทุกคนแก้ได้ทุก namespace                     | สร้าง AppProject แยกทีม               |
| ไม่แยก App Repo กับ Manifest Repo       | CI/CD ซับซ้อน, permission ปนกัน              | แยก repo ตาม concern                  |

### 🧪 Lab 14: สร้าง AppProject + RBAC

**วัตถุประสงค์:** กำหนดให้ dev-team sync ได้เฉพาะ dev namespace เท่านั้น

```bash
# สร้าง AppProject
kubectl apply -f appproject-dev-team.yaml

# สร้าง Application ภายใต้ dev-team project
# ใน argocd-app.yaml เปลี่ยน spec.project เป็น "dev-team"

# ทดสอบ: ลอง deploy ไป production namespace → ต้อง error!
```

### 🧪 Lab 15: สร้าง Sealed Secret

**วัตถุประสงค์:** Encrypt secret → commit ใน Git → Argo CD deploy → verify ค่า secret ใน pod

```bash
# สร้าง secret
kubectl create secret generic app-secret \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_PASSWORD=mysecretpassword \
  --dry-run=client -o yaml > app-secret.yaml

# Encrypt
kubeseal --format yaml < app-secret.yaml > sealed-app-secret.yaml

# Commit & push (Argo CD จะ deploy ให้)
git add sealed-app-secret.yaml
git commit -m "feat: add sealed app secret"
git push origin main

# Verify ใน pod
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

### 🎯 Real-world Scenario

**สถานการณ์:** 3 ทีม (backend, frontend, data) ต้องการ deploy อิสระจากกัน แต่ต้องไม่ล้ำ namespace กัน

**ออกแบบ AppProject อย่างไร?**

```
AppProject: backend-team
  sourceRepos: [backend-manifests]
  destinations: [namespace: backend-*]

AppProject: frontend-team
  sourceRepos: [frontend-manifests]
  destinations: [namespace: frontend-*]

AppProject: data-team
  sourceRepos: [data-manifests]
  destinations: [namespace: data-*]
```

---

## Section 8: Best Practices + Final End-to-End Workshop

`14:30–16:00 (90 นาที) | Workshop`

### 8.1 GitOps Anti-patterns

| Anti-pattern ❌                                    | ปัญหา                                | แก้ไข ✅                                  |
| ------------------------------------------------- | ------------------------------------- | ----------------------------------------- |
| Push image tag ตรงเข้า production                  | ไม่ผ่าน staging, ไม่มี review          | ใช้ promotion flow: dev → staging → prod  |
| Merge code แล้ว skip staging                       | ไม่ได้ทดสอบก่อน production             | บังคับ staging deploy + smoke test        |
| ไม่มี approval gate                               | ใครก็ merge ไป production ได้           | ใช้ GitHub PR review + branch protection  |
| ใช้ Argo CD เป็น CI tool                           | Argo CD ไม่ build image, ไม่ run test  | Argo CD = CD only, ใช้ GitHub Actions = CI |
| Auto-Sync ทุก environment                         | production deploy ทันทีที่ merge       | manual sync สำหรับ production              |

### 8.2 Argo CD Limitations — สิ่งที่ Argo CD ไม่ทำ

```
┌────────────── CI/CD Pipeline ──────────────┐
│                                             │
│  CI (GitHub Actions)    CD (Argo CD)        │
│  ┌──────────────────┐  ┌────────────────┐   │
│  │ ✅ Build image    │  │ ✅ Deploy app   │   │
│  │ ✅ Run tests      │  │ ✅ Sync state   │   │
│  │ ✅ Push to GHCR   │  │ ✅ Self-Heal    │   │
│  │ ✅ Update manifest│  │ ✅ Rollback     │   │
│  │ ❌ Deploy app     │  │ ❌ Build image  │   │
│  │ ❌ Manage cluster │  │ ❌ Run tests    │   │
│  └──────────────────┘  └────────────────┘   │
│                                             │
│  CI + CD = Complete Pipeline ✅              │
└─────────────────────────────────────────────┘
```

> **จำให้ขึ้นใจ:** Argo CD **ไม่ใช่** CI tool — ไม่ build image, ไม่ run test — ต้องคู่กับ CI (GitHub Actions) เสมอ

### 8.3 Scaling Team — ApplicationSet

**ApplicationSet** สร้างหลาย Application จาก template เดียว — เหมาะกับ multi-cluster / multi-team:

```yaml
# applicationset-multi-env.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app-set
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - env: dev
            replicas: "1"
          - env: staging
            replicas: "2"
          - env: production
            replicas: "3"
  template:
    metadata:
      name: "my-app-{{env}}"
    spec:
      project: default
      source:
        repoURL: https://github.com/username/my-app-manifests.git
        targetRevision: main
        path: "overlays/{{env}}"
      destination:
        server: https://kubernetes.default.svc
        namespace: "{{env}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

> **ผลลัพธ์:** สร้าง 3 Argo CD Applications อัตโนมัติ: `my-app-dev`, `my-app-staging`, `my-app-production`

### 8.4 What Next — เส้นทางสู่ Advanced

| หัวข้อ              | คำอธิบาย                                              |
| ------------------- | ----------------------------------------------------- |
| **Argo Rollouts**   | Progressive Delivery — Canary, Blue-Green deployment   |
| **Argo Workflows**  | Kubernetes-native workflow engine                      |
| **Vault Plugin**    | integrate HashiCorp Vault สำหรับ secret management     |
| **Multi-cluster**   | จัดการหลาย cluster จาก Argo CD ที่เดียว                |
| **Image Updater**   | Argo CD Image Updater — auto-update image tag          |
| **Notifications**   | ส่ง Slack/Email เมื่อ sync สำเร็จ/ล้มเหลว              |

---

### 🧪 Final End-to-End Workshop (60 นาที)

ผู้เรียนทำ pipeline สมบูรณ์ตั้งแต่ต้นจนจบด้วยตัวเอง โดยวิทยากรเป็น facilitator:

#### Lab 16: แก้ Code → GitHub Actions Build → Update Manifest

**ขั้นตอนที่ 1:** แก้ code ใน app repo

```bash
# แก้ไข source code
vim src/index.js   # เปลี่ยน version หรือ content

# Commit & push
git add .
git commit -m "feat: update app version to v2"
git push origin main
```

**ขั้นตอนที่ 2:** GitHub Actions build image + update manifest repo

```yaml
# เพิ่ม step ใน CI workflow เพื่อ update manifest repo
- name: Update manifest repo
  run: |
    git clone https://github.com/${{ github.actor }}/my-app-manifests.git
    cd my-app-manifests/overlays/dev
    kustomize edit set image ghcr.io/${{ github.repository }}:${{ github.sha }}
    git config user.name "github-actions"
    git config user.email "actions@github.com"
    git add .
    git commit -m "deploy: update image to ${{ github.sha }}"
    git push
```

#### Lab 17: Argo CD Auto-Sync → Deploy → Verify

**ขั้นตอน:**
1. ดู Argo CD UI — สถานะเปลี่ยนจาก **Synced** → **OutOfSync**
2. Argo CD Auto-Sync → **Syncing** → **Synced + Healthy**
3. Verify ใน browser: เปิด app → เห็น version ใหม่

```bash
# ตรวจสอบ
argocd app get my-app-dev
kubectl get pods -n dev
kubectl logs -n dev deployment/dev-my-app
```

#### Lab 18: Rollback ด้วย Git Revert

**ขั้นตอน:**

```bash
# ใน manifest repo
git log --oneline -5    # ดูประวัติ

# Revert commit ล่าสุด
git revert HEAD --no-edit
git push origin main

# ดู Argo CD UI — sync กลับเป็น version เดิมอัตโนมัติ
argocd app get my-app-dev
```

#### Lab 19: Break & Self-Heal

**ขั้นตอน:**

```bash
# "Break" cluster — ลบ Deployment โดยตรง
kubectl delete deployment dev-my-app -n dev

# ดู Argo CD UI
# สถานะ: OutOfSync → Missing
# รอ 1-3 นาที → Self-Heal สร้าง Deployment ใหม่อัตโนมัติ

# ยืนยัน
kubectl get deployment dev-my-app -n dev
argocd app get my-app-dev
```

### 8.5 End-to-End Flow — สิ่งที่เราทำได้ครบ 2 วัน

```
┌──────────────────── Complete GitOps Pipeline ────────────────────┐
│                                                                   │
│  1. Code Change        2. GitHub Actions CI                      │
│  ┌──────────────┐     ┌─────────────────────┐                    │
│  │ Developer    │────▶│ Build Docker Image  │                    │
│  │ git push     │     │ Push to GHCR        │                    │
│  └──────────────┘     │ Update Manifest Repo│                    │
│                       └──────────┬──────────┘                    │
│                                  │                               │
│  3. Manifest Repo      4. Argo CD Detection                     │
│  ┌──────────────┐     ┌─────────────────────┐                    │
│  │ image tag    │────▶│ "OutOfSync          │                    │
│  │ updated!     │     │  detected!"         │                    │
│  └──────────────┘     └──────────┬──────────┘                    │
│                                  │                               │
│  5. Auto-Sync          6. Kubernetes Deploy                     │
│  ┌──────────────┐     ┌─────────────────────┐                    │
│  │ Argo CD      │────▶│ New version         │                    │
│  │ apply YAML   │     │ deployed! ✅        │                    │
│  └──────────────┘     └─────────────────────┘                    │
│                                                                   │
│  ⚡ Self-Heal: ลบ resource → Argo CD สร้างกลับ                   │
│  🔄 Rollback: git revert → Argo CD sync version เดิม             │
│  🔍 Drift Detection: แก้ cluster ตรง → Argo CD revert            │
└───────────────────────────────────────────────────────────────────┘
```

---

### สรุป Day 2

ในวันที่ 2 เราได้เรียนรู้ Argo CD อย่างเจาะลึกและนำไปใช้งานจริง:

**Section 5: Argo CD Deep Dive**

- ✅ ติดตั้ง Argo CD (Helm install + CLI + UI)
- ✅ สร้าง Application ด้วย Declarative YAML
- ✅ Auto-Sync, Self-Heal, Drift Detection
- ✅ Rollback ด้วย argocd CLI และ git revert
- ✅ Sync Waves & Resource Hooks (PreSync/PostSync)

**Section 6: Kustomize Multi-environment + Helm Overview**

- ✅ Kustomize base + overlays สำหรับ dev / staging / prod
- ✅ images patch, commonLabels, namePrefix, replicas
- ✅ Argo CD render Kustomize ได้โดยตรง
- ✅ Helm overview — เมื่อไหร่ใช้ Helm vs Kustomize

**Section 7: Production Design**

- ✅ Git structure: mono-repo vs multi-repo
- ✅ Image tagging: Git SHA, SemVer (ห้าม latest!)
- ✅ AppProject + RBAC สำหรับ multi-tenancy
- ✅ Sealed Secrets: encrypt secret → commit ใน Git ได้ปลอดภัย
- ✅ Anti-patterns ที่ต้องหลีกเลี่ยง

**Section 8: Best Practices + End-to-End Workshop**

- ✅ GitOps anti-patterns และ Argo CD limitations
- ✅ ApplicationSet สำหรับ multi-cluster / multi-team
- ✅ **End-to-End Pipeline:** Code → GitHub Actions → GHCR → Update Manifest → Argo CD Auto-Sync → Kubernetes Deploy
- ✅ Rollback ด้วย git revert + Self-Heal ทดสอบจริง

> 🎉 **ยินดีด้วย!** ผู้เรียนสามารถออกแบบและ implement GitOps pipeline ด้วย Argo CD ได้ครบวงจร ตั้งแต่ CI (GitHub Actions) จนถึง CD (Argo CD) พร้อม production-ready security (RBAC, Sealed Secrets) และ multi-environment management (Kustomize)
