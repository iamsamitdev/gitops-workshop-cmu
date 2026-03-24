# Section 5 & 6: Argo CD Deep Dive + Kustomize Multi-environment

> **Workshop:** GitOps with Argo CD (2026 Edition)  
> **วิทยากร:** อาจารย์สามิตร โกยม | IT Genius Institute  
> **Day 2 — Section 5 (09:00–10:30) | Section 6 (10:45–12:00)**

---

## Section 5: Argo CD Deep Dive

`09:00–10:30 (90 นาที) | Hands-on Lab`

### 5.1 ติดตั้ง Argo CD บน Kubernetes

**ขั้นตอนที่ 1:** สร้าง namespace และติดตั้ง Argo CD

```bash
# สร้าง namespace สำหรับ Argo CD
kubectl create namespace argocd

# ติดตั้ง Argo CD
# ⚠️  ต้องใช้ --server-side เสมอ! ไม่งั้นจะเจอ error:
#    "metadata.annotations: Too long: may not be more than 262144 bytes"
#    เพราะ CRD ของ Argo CD ใหม่ใหญ่เกิน 256KB limit ของ client-side apply
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side

# รอจน pod ทั้งหมดพร้อม (ใช้เวลาประมาณ 2-3 นาที)
kubectl get pods -n argocd -w
```

> **⚠️ ถ้ารัน client-side ไปก่อนแล้วแล้วเจอ conflict** ให้เพิ่ม `--force-conflicts`:
> ```bash
> kubectl apply -n argocd \
>   -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
>   --server-side --force-conflicts
> ```

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

# Windows (PowerShell — ใช้ winget)
winget install --id argoproj.argocd --source winget

# Login ผ่าน CLI
argocd login localhost:8080 --username admin --password <password> --insecure
```

---

### 5.2 สร้าง Application — Declarative YAML

ต่อจาก manifest repo ที่ทำใน Day 1 โดยตรง:

```yaml
# 📁 gitops/applications/app-dev.yaml
# (ดูไฟล์ตัวอย่างสมบูรณ์ได้ที่ gitops/applications/app-dev.yaml)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/<username>/gitops-workshop-cmu.git
    targetRevision: main
    path: infra/kustomize/overlays/dev    # path ที่เก็บ manifests

  destination:
    server: https://kubernetes.default.svc
    namespace: dev

  syncPolicy:
    automated:                 # Auto-Sync: เปิด/ปิดได้
      prune: true              # ลบ resource ที่ไม่มีใน Git
      selfHeal: true           # แก้ไขเมื่อมีคนเปลี่ยน cluster ตรง
    syncOptions:
      - CreateNamespace=true
```

```bash
# apply จาก GitOps layer ของ project นี้
kubectl apply -f gitops/applications/app-dev.yaml
```

> **สังเกต:** Argo CD Application เองก็เป็น Kubernetes resource (CRD) — สร้างได้ด้วย `kubectl apply` เหมือน resource อื่น

---

### 5.3 Sync Lifecycle — เข้าใจสถานะของ Application

```
┌───────────────────── Argo CD Sync Lifecycle ─────────────────────┐
│                                                                  │
│   ┌──────────┐    ┌─────────────┐    ┌──────────┐    ┌─────────┐ │
│   │  Synced  │───▶│ OutOfSync  │───▶│ Syncing  │──▶│ Healthy │ │
│   │  ✅      │    │  ⚠️        │    │  🔄     │    │  💚     │ │
│   └──────────┘    └─────────────┘    └──────────┘    └─────────┘ │
│        ▲                                                  │      │
│        └──────────────────────────────────────────────────┘      │
│                                                                  │
│   Synced     = Git state == Cluster state                        │
│   OutOfSync  = Git state ≠ Cluster state (ต้อง sync)              │
│   Syncing    = กำลัง apply changes                                │
│   Healthy    = ทุก resource พร้อมใช้งาน                            │
│   Degraded   = บาง resource มีปัญหา                               │
│   Missing    = resource ยังไม่ถูกสร้าง                               │
└──────────────────────────────────────────────────────────────────┘
```

| สถานะ         | ความหมาย                                    | สี    |
| ------------- | ------------------------------------------- | ----- |
| **Synced**    | Git state = Cluster state                   | 🟢 เขียว |
| **OutOfSync** | Git state ≠ Cluster state                   | 🟡 เหลือง |
| **Unknown**   | ไม่สามารถตรวจสอบได้                          | ⚪ เทา   |
| **Healthy**   | ทุก resource ทำงานปกติ                       | 💚 เขียว |
| **Degraded**  | บาง resource มีปัญหา                         | 🔴 แดง  |
| **Progressing** | กำลัง rollout / deploy อยู่                 | 🔵 น้ำเงิน |

---

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

---

### 5.5 Drift Detection

**Drift** = สถานะใน cluster ไม่ตรงกับที่กำหนดใน Git

```
┌─── Git Repo ───┐        ┌─── Cluster ───┐
│ replicas: 3    │   ≠    │ replicas: 5   │  ← มีคนแก้ตรง!
│ image: v1.2.3  │   =    │ image: v1.2.3 │
└────────────────┘        └───────────────┘
         │                         │
         └────── Argo CD ──────────┘
               "OutOfSync! ⚠️"
```

> **สำคัญ:** Argo CD สแกน cluster ทุก **3 นาที** (default) — ถ้าใครแก้อะไรใน cluster โดยตรง Argo CD จะรู้ทันทีในรอบถัดไป

---

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

---

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

---

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

---

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

---

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
│                                                             │
│  base/                    (config กลาง — ใช้ร่วมกัน)           │
│  ├── deployment.yaml       replicas: 1, image: my-app       │
│  ├── service.yaml          port: 80                         │
│  └── kustomization.yaml    resources: [deployment, service] │
│                                                             │
│  overlays/                                                  │
│  ├── dev/                  (dev environment)                │
│  │   └── kustomization.yaml  replicas: 1, namePrefix: dev-  │
│  ├── staging/              (staging environment)            │
│  │   └── kustomization.yaml  replicas: 2                    │
│  └── prod/                 (production environment)         │
│      └── kustomization.yaml  replicas: 3, namePrefix: prod- │
│                                                             │
│  ผลลัพธ์: แต่ละ env ได้ YAML ที่ต่างกันโดยไม่ต้อง copy ทั้งไฟล์        │
└─────────────────────────────────────────────────────────────┘
```

---

### 6.2 Base — Config กลาง

```yaml
# 📁 infra/kustomize/base/deployment.yaml
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
# 📁 infra/kustomize/base/service.yaml
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
# 📁 infra/kustomize/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

---

### 6.3 Overlays — Config เฉพาะ Environment

**Dev Overlay:**

```yaml
# 📁 infra/kustomize/overlays/dev/kustomization.yaml
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

**Staging Overlay:**

```yaml
# 📁 infra/kustomize/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
namePrefix: staging-
commonLabels:
  environment: staging
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
images:
  - name: ghcr.io/username/my-app
    newTag: staging-latest
```

**Production Overlay:**

```yaml
# 📁 infra/kustomize/overlays/production/kustomization.yaml
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

---

### 6.4 เทคนิค Kustomize ที่ใช้บ่อย

| เทคนิค              | คำอธิบาย                                          | ตัวอย่าง                           |
| -------------------- | ------------------------------------------------- | ---------------------------------- |
| **images**           | เปลี่ยน image tag โดยไม่แก้ base                   | `newTag: v1.2.3`                  |
| **replicas**         | เปลี่ยนจำนวน replicas                              | `- name: my-app` `count: 3`      |
| **namePrefix**       | เพิ่ม prefix ให้ชื่อ resource                       | `namePrefix: prod-`              |
| **commonLabels**     | เพิ่ม label ให้ทุก resource                         | `environment: production`        |
| **patches**          | แก้ไขค่าเฉพาะจุด (JSON patch)                      | replace replicas, add env vars   |
| **configMapGenerator** | สร้าง ConfigMap จาก file หรือ literal             | `configMapGenerator:` + `literals` |

---

### 6.5 images patch — CI/CD ต้องการสิ่งนี้

ในทางปฏิบัติ CI pipeline จะ update image tag ใน overlay โดยใช้ `kustomize edit`:

```bash
# CI pipeline update image tag ใน overlay
cd infra/kustomize/overlays/production
kustomize edit set image ghcr.io/username/my-app:v1.2.4

# ดูผลลัพธ์ (preview ก่อน apply)
kustomize build infra/kustomize/overlays/production
```

> **Best Practice:** CI pipeline ไม่ควรแก้ YAML ตรง — ใช้ `kustomize edit set image` แทน เพื่อลดโอกาสผิดพลาด

---

### 6.6 Kustomize ร่วมกับ Argo CD

Argo CD สามารถ render Kustomize ได้โดยตรง — ไม่ต้องติดตั้ง Kustomize CLI แยก:

```yaml
# 📁 gitops/applications/app-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<username>/gitops-workshop-cmu.git
    targetRevision: main
    path: infra/kustomize/overlays/dev    # ← ชี้ไปที่ overlay ของ dev
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

---

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

---

### 🧪 Lab 12: ปรับ Manifest Repo เป็น Kustomize Structure

**วัตถุประสงค์:** ปรับ manifest repo จาก Day 1 ให้เป็น Kustomize structure

**ขั้นตอนที่ 1:** สร้างโครงสร้าง base + overlays

```bash
mkdir -p base overlays/dev overlays/staging overlays/prod
mv deployment.yaml service.yaml base/
```

**ขั้นตอนที่ 2:** สร้าง `base/kustomization.yaml`, `overlays/dev/kustomization.yaml`, `overlays/prod/kustomization.yaml` ตาม Section 6.2–6.3

**ขั้นตอนที่ 3:** ทดสอบ

```bash
# Preview YAML ที่ Kustomize จะ generate
kustomize build overlays/dev
kustomize build overlays/prod
```

---

### 🧪 Lab 13: ทดลองเปลี่ยนค่าแต่ละ Environment

**วัตถุประสงค์:** เห็น Argo CD render Kustomize ต่างกันตาม environment

- dev: `replicas=1`
- staging: `replicas=2`
- prod: `replicas=3`
- สังเกตจาก Argo CD UI ว่า dev app กับ prod app มีค่าต่างกัน

```bash
# Commit & push
git add .
git commit -m "refactor: restructure to Kustomize base/overlays"
git push origin main

# สร้าง Argo CD Application สำหรับ dev และ prod
kubectl apply -f gitops/applications/app-dev.yaml
kubectl apply -f gitops/applications/app-production.yaml

# ตรวจสอบ
argocd app list
kubectl get pods -n dev
kubectl get pods -n production
```

---

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

## สรุป Section 5 & 6

| หัวข้อ | สิ่งที่ได้เรียนรู้ |
| --- | --- |
| **S5: Argo CD** | ติดตั้ง, Declarative App, Auto-Sync, Self-Heal, Drift Detection, Rollback, Sync Waves |
| **S6: Kustomize** | Base + Overlays, images patch, namePrefix, ร่วมกับ Argo CD |
| **S6: Helm** | Overview, เทียบกับ Kustomize, demo deploy nginx |

> **ต่อไป:** Section 7 — Production Design (Git Structure, RBAC, Sealed Secrets)
