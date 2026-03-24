# Section 7 & 8: Production Design + Best Practices & End-to-End Workshop

> **Workshop:** GitOps with Argo CD (2026 Edition)  
> **วิทยากร:** อาจารย์สามิตร โกยม | IT Genius Institute  
> **Day 2 — Section 7 (13:00–14:15) | Section 8 (14:30–16:00)**

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

---

### 7.2 Image Tagging ใน Production

| Strategy         | ตัวอย่าง              | Rollback ทำอย่างไร                    |
| ---------------- | --------------------- | ------------------------------------- |
| **Git SHA**      | `my-app:a1b2c3d`     | `git revert` → CI build ใหม่ → tag ใหม่ |
| **SemVer**       | `my-app:v1.2.3`      | แก้ overlay → `newTag: v1.2.2`        |
| **Environment**  | `my-app:staging`      | ❌ ไม่แนะนำ — mutable tag             |

> **Best Practice:** ใช้ **immutable tag** เสมอ (Git SHA หรือ SemVer) — ห้ามใช้ `latest` หรือ environment tag ใน production

---

### 7.3 AppProject & RBAC — Multi-tenancy

**AppProject** = ขอบเขตสำหรับแต่ละทีม — กำหนดว่าทีมไหนเข้าถึง repo ไหน, deploy ไป namespace ไหน

```yaml
# 📁 gitops/appproject/project-dev.yaml
# (ดูไฟล์ตัวอย่างได้ที่ gitops/appproject/project-dev.yaml)
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

---

### 7.4 Sealed Secrets — เก็บ Secret ใน Git อย่างปลอดภัย

**ปัญหา:** Kubernetes Secret เป็นแค่ base64 — ถ้า commit ใน Git ใครเปิดก็เห็น

**Sealed Secrets แก้ปัญหา:** encrypt secret ด้วย public key → commit ใน Git ได้ → Sealed Secrets controller ใน cluster decrypt ให้

```
┌─────────────── Sealed Secrets Flow ───────────────┐
│                                                   │
│  1. สร้าง Secret             2. Encrypt            │
│  ┌──────────────────┐       ┌──────────────────┐  │
│  │ apiVersion: v1   │──────▶│ apiVersion:      │ │
│  │ kind: Secret     │ kubeseal │ bitnami.com/v1 │ │
│  │ data:            │       │ kind: SealedSecret│ │
│  │   password: xxx  │       │ spec:            │  │
│  └──────────────────┘       │   encryptedData: │  │
│    (ห้าม commit!)           │     password: ...│   │
│                             └────────┬─────────┘  │
│                                      │ ✅ commit!│
│  3. Git Repo        4. Argo CD       │            │
│  ┌──────────┐      ┌────────────┐    │            │
│  │ sealed-  │◀─────│ apply      │◀───┘           │
│  │ secret.  │      │ sealed-    │                 │
│  │ yaml     │      │ secret     │                 │
│  └──────────┘      └─────┬──────┘                 │
│                          │                        │
│  5. Sealed Secrets Controller decrypt             │
│  ┌──────────────────────────────┐                 │
│  │ SealedSecret → Secret        │                 │
│  │ Pod สามารถอ่าน Secret ได้      │                 │
│  └──────────────────────────────┘                 │
└──────────────────────────────────────────────────┘
```

**ขั้นตอน:**

```bash
# ติดตั้ง Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.0/controller.yaml

# ติดตั้ง kubeseal CLI
brew install kubeseal   # macOS

# สร้าง Secret ปกติ (ไม่ apply จริง — dry-run)
kubectl create secret generic my-secret \
  --from-literal=DB_PASSWORD=supersecret123 \
  --dry-run=client -o yaml > /tmp/my-secret.yaml

# Encrypt ด้วย kubeseal — ผลลัพธ์ส่งตรงไป folder ที่ถูกต้อง
kubeseal --format yaml < /tmp/my-secret.yaml > gitops/secrets/sealed-secret.yaml

# ลบไฟล์ต้นฉบับทันที! (ห้ามเก็บไว้!)
rm /tmp/my-secret.yaml

# Commit gitops/secrets/sealed-secret.yaml ใน Git (ปลอดภัย!)
git add gitops/secrets/sealed-secret.yaml
git commit -m "feat: add sealed database secret"
git push origin main
```

---

### 7.5 Anti-patterns ที่ควรหลีกเลี่ยง

| Anti-pattern ❌                         | ทำไมถึงเป็นปัญหา                            | Best Practice ✅                       |
| --------------------------------------- | ------------------------------------------- | -------------------------------------- |
| เก็บ Secret ใน Git (plain text)          | ใครเข้า Git ก็เห็น password                  | ใช้ Sealed Secrets หรือ Vault           |
| ใช้ `latest` tag                        | ไม่รู้ว่า version อะไร, ไม่ reproducible      | ใช้ Git SHA หรือ SemVer                |
| แก้ cluster โดยตรง (`kubectl edit`)      | Drift — Argo CD จะ revert กลับ              | แก้ที่ Git เสมอ                        |
| ไม่มี AppProject / RBAC                 | ทุกคนแก้ได้ทุก namespace                     | สร้าง AppProject แยกทีม               |
| ไม่แยก App Repo กับ Manifest Repo       | CI/CD ซับซ้อน, permission ปนกัน              | แยก repo ตาม concern                  |

---

### 🧪 Lab 14: สร้าง AppProject + RBAC

**วัตถุประสงค์:** กำหนดให้ dev-team sync ได้เฉพาะ dev namespace เท่านั้น

```bash
# สร้าง AppProject
kubectl apply -f gitops/appproject/project-dev.yaml

# สร้าง Application ภายใต้ dev-team project
# ใน app-dev.yaml เปลี่ยน spec.project เป็น "dev-team"

# ทดสอบ: ลอง deploy ไป production namespace → ต้อง error!
```

---

### 🧪 Lab 15: สร้าง Sealed Secret

**วัตถุประสงค์:** Encrypt secret → commit ใน Git → Argo CD deploy → verify ค่า secret ใน pod

```bash
# สร้าง secret (dry-run — ไม่ apply จริง)
kubectl create secret generic app-secret \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_PASSWORD=mysecretpassword \
  --namespace=dev \
  --dry-run=client -o yaml > /tmp/app-secret.yaml

# Encrypt — ผลลัพธ์ส่งไปที่ gitops/secrets/
kubeseal --format yaml --namespace dev \
  < /tmp/app-secret.yaml \
  > gitops/secrets/sealed-app-secret.yaml

# ลบไฟล์ต้นฉบับทันที!
rm /tmp/app-secret.yaml

# Commit & push (Argo CD จะ deploy ให้)
git add gitops/secrets/sealed-app-secret.yaml
git commit -m "feat: add sealed app secret"
git push origin main

# Verify ใน pod
kubectl get secret app-secret -n dev -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

---

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

---

### 8.2 Argo CD Limitations — สิ่งที่ Argo CD ไม่ทำ

```
┌────────────── CI/CD Pipeline ──────────────┐
│                                            │
│  CI (GitHub Actions)    CD (Argo CD)       │
│  ┌──────────────────┐  ┌────────────────┐  │
│  │ ✅ Build image  │  │ ✅ Deploy app  │  │
│  │ ✅ Run tests    │  │ ✅ Sync state  │  │
│  │ ✅ Push to GHCR │  │ ✅ Self-Heal   │  │
│  │ ✅ Update manifest│  │ ✅ Rollback  │  │
│  │ ❌ Deploy app   │  │ ❌ Build image │  │
│  │ ❌ Manage cluster │  │ ❌ Run tests │  │
│  └──────────────────┘  └────────────────┘  │
│                                            │
│  CI + CD = Complete Pipeline ✅           │
└────────────────────────────────────────────┘
```

> **จำให้ขึ้นใจ:** Argo CD **ไม่ใช่** CI tool — ไม่ build image, ไม่ run test — ต้องคู่กับ CI (GitHub Actions) เสมอ

---

### 8.3 Scaling Team — ApplicationSet

**ApplicationSet** สร้างหลาย Application จาก template เดียว — เหมาะกับ multi-cluster / multi-team:

```yaml
# 📁 gitops/applicationset/multi-env-appset.yaml
# (ดูไฟล์ตัวอย่างสมบูรณ์ได้ที่ gitops/applicationset/multi-env-appset.yaml)
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
        repoURL: https://github.com/<username>/gitops-workshop-cmu.git
        targetRevision: main
        path: "infra/kustomize/overlays/{{env}}"
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

---

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
# 📁 .github/workflows/update-manifest.yml — step ที่เพิ่มใน CI workflow
# (ดูไฟล์ตัวอย่างสมบูรณ์ได้ที่ .github/workflows/update-manifest.yml)
- name: Update manifest repo
  run: |
    cd infra/kustomize/overlays/dev
    kustomize edit set image ghcr.io/${{ github.repository }}:${{ github.sha }}
    git config user.name "github-actions"
    git config user.email "actions@github.com"
    git add .
    git commit -m "deploy: update image to ${{ github.sha }}"
    git push
```

---

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

---

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

---

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

---

### 8.5 End-to-End Flow — สิ่งที่เราทำได้ครบ 2 วัน

```
┌──────────────────── Complete GitOps Pipeline ───────────────────┐
│                                                                 │
│  1. Code Change        2. GitHub Actions CI                     │
│  ┌──────────────┐     ┌─────────────────────┐                   │
│  │ Developer    │────▶│ Build Docker Image  │                   │
│  │ git push     │     │ Push to GHCR        │                   │
│  └──────────────┘     │ Update Manifest Repo│                   │
│                       └──────────┬──────────┘                   │
│                                  │                              │
│  3. Manifest Repo      4. Argo CD Detection                     │
│  ┌──────────────┐     ┌─────────────────────┐                   │
│  │ image tag    │────▶│ "OutOfSync          │                   │
│  │ updated!     │     │  detected!"         │                   │
│  └──────────────┘     └──────────┬──────────┘                   │
│                                  │                              │
│  5. Auto-Sync          6. Kubernetes Deploy                     │
│  ┌──────────────┐     ┌─────────────────────┐                   │
│  │ Argo CD      │────▶│ New version         │                  │
│  │ apply YAML   │     │ deployed! ✅        │                  │
│  └──────────────┘     └─────────────────────┘                   │
│                                                                 │
│  ⚡ Self-Heal: ลบ resource → Argo CD สร้างกลับ                   │
│  🔄 Rollback: git revert → Argo CD sync version เดิม             │
│  🔍 Drift Detection: แก้ cluster ตรง → Argo CD revert            │
└─────────────────────────────────────────────────────────────────┘
```

---

## สรุป Day 2

ในวันที่ 2 เราได้เรียนรู้ Argo CD อย่างเจาะลึกและนำไปใช้งานจริง:

**Section 5: Argo CD Deep Dive**

- ✅ ติดตั้ง Argo CD (kubectl install + CLI + UI)
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
