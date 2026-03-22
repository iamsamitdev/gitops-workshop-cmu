# Section 1 & 2 — DevOps → GitOps & Kubernetes Fundamentals

> **Workshop:** GitOps with Argo CD (2026 Edition)  
> **วันที่ 1 | 09:00–12:00**  
> **Section 1:** 09:00–10:30 · Concept + Visual Storytelling  
> **Section 2:** 10:45–12:00 · Hands-on Lab

---

## Section 1: DevOps → GitOps: ทำไมต้องเปลี่ยน?

`09:00–10:30 (90 นาที) | Concept + Visual Storytelling`

### 1.1 Pain Point จริงของ Traditional Deployment

ในองค์กรที่ใช้ Traditional CI/CD pipeline ปัญหาที่พบบ่อย:

| ปัญหา                         | อาการ                                                      |
| ----------------------------- | ---------------------------------------------------------- |
| 🔥 Deployment ผิดพลาด         | deploy version ผิด, config ผิด environment                  |
| 🔄 Rollback ยาก               | ไม่รู้ว่า production มี version อะไรอยู่ ต้องหาเอง          |
| 🤷 ไม่รู้ว่าใคร deploy อะไร    | ไม่มี audit trail, ทีมโทษกัน                               |
| 💻 "Works on my machine"      | staging กับ production config ต่างกัน                       |
| 🔑 Credential กระจัดกระจาย    | CI server เก็บ kubeconfig, token, password ของทุก cluster    |
| 📊 ไม่มี Drift Detection      | ใครแก้ cluster ตรง ไม่มีใครรู้                               |

---

### 1.2 Traditional CI/CD — Push-based Model

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐
│   Dev    │──▶│  CI/CD   │───▶│  Build   │──▶│   kubectl    │
│  Push    │    │  Server  │    │  & Test  │    │   apply      │
│  Code    │    │ (GitHub  │    │          │    │   (Push to   │
│          │    │ Actions) │    │          │    │   Cluster)   │
└──────────┘    └──────────┘    └──────────┘    └──────┬───────┘
                                                       │
                                                       ▼
                                               ┌──────────────┐
                                               │  Kubernetes  │
                                               │   Cluster    │
                                               └──────────────┘
```

**ปัญหาของ Push-based:**

- CI server ต้องมี **credential** เข้าถึง cluster (kubeconfig) — ถ้า CI ถูก hack cluster ก็โดนด้วย
- ไม่มี **drift detection** — ถ้าใครแก้ cluster ตรง CI ไม่รู้
- **Rollback** ต้อง re-run pipeline ใหม่ — ช้าและเสี่ยง
- ไม่มี **single source of truth** — state อยู่ที่ cluster ไม่ใช่ Git

---

### 1.3 GitOps แก้ปัญหาอย่างไร?

**GitOps** คือวิธีปฏิบัติที่ใช้ **Git เป็น single source of truth** สำหรับ infrastructure และ application:

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│   Dev    │──▶│   Git    │◀──▶│ Argo CD  │
│  Push    │    │  Repo    │    │ (Pull &  │
│  Code    │    │ (Source  │    │  Sync)   │
│          │    │ of Truth)│    │          │
└──────────┘    └──────────┘    └────┬─────┘
                                     │ ▲
                                     ▼ │ Reconcile
                               ┌──────────────┐
                               │  Kubernetes  │
                               │   Cluster    │
                               └──────────────┘
```

**GitOps แก้ทุกปัญหา:**

| ปัญหา                      | GitOps แก้ด้วย                                        |
| --------------------------- | ----------------------------------------------------- |
| Deployment ผิดพลาด          | YAML ใน Git ผ่าน review ก่อน merge                    |
| Rollback ยาก                | `git revert` → Argo CD sync กลับอัตโนมัติ              |
| ไม่รู้ว่าใคร deploy อะไร    | Git commit history = audit trail ครบถ้วน               |
| Config ต่างกัน              | ทุก environment มี config ใน Git — reproduce ได้ 100%  |
| Credential กระจัดกระจาย     | Argo CD อยู่ใน cluster — ไม่ต้อง expose credential ออก |
| ไม่มี Drift Detection       | Argo CD เฝ้าดู cluster ตลอดเวลา — detect และ revert   |

---

### 1.4 GitOps 4 หลักการ (Principles)

GitOps ถูกนิยามโดย **OpenGitOps** (CNCF Sandbox) ด้วย 4 หลักการ:

| หลักการ                      | คำอธิบาย                                                      |
| ---------------------------- | ------------------------------------------------------------- |
| **1. Declarative**           | ระบบทั้งหมดต้องอธิบายได้ด้วย declaration (YAML/JSON)            |
| **2. Versioned & Immutable** | desired state ถูกเก็บใน Git — มี version, ย้อนกลับได้, tamper-proof |
| **3. Pulled Automatically**  | agent (Argo CD) ดึง desired state จาก Git มา apply อัตโนมัติ    |
| **4. Continuously Reconciled** | agent เฝ้า reconcile ตลอดเวลา — ถ้า actual ≠ desired → แก้ไข  |

---

### 1.5 Push-based vs Pull-based — เปรียบเทียบ

| ลักษณะ              | Push-based (CI/CD ดั้งเดิม)        | Pull-based (GitOps)                     |
| ------------------- | ---------------------------------- | --------------------------------------- |
| **ใครเป็นคน deploy** | CI server push เข้า cluster        | Agent ใน cluster pull จาก Git           |
| **Credential**       | CI ต้องมี kubeconfig               | Agent อยู่ใน cluster แล้ว (ไม่ต้อง expose) |
| **Drift Detection**  | ❌ ไม่มี                           | ✅ ตลอดเวลา                             |
| **Rollback**         | ต้อง re-run pipeline               | `git revert` → auto sync               |
| **Audit Trail**      | ดูจาก CI logs                      | ดูจาก Git commit history               |
| **Security**         | Credential อยู่นอก cluster         | Credential อยู่ใน cluster              |
| **ตัวอย่าง Tool**    | Jenkins, GitHub Actions (push mode) | Argo CD, Flux CD                       |

---

### 1.6 Argo CD คืออะไร?

**Argo CD** คือ declarative, GitOps continuous delivery tool สำหรับ Kubernetes:

- 🎓 **CNCF Graduated Project** — ผ่านการรับรองว่า production-ready
- 🔄 **Pull-based** — ดึง desired state จาก Git มา sync ตลอดเวลา
- 🖥️ **มี Web UI** — เห็น application status แบบ real-time
- 🔧 **รองรับหลาย config tool** — Plain YAML, Kustomize, Helm, Jsonnet
- 🏢 **Multi-cluster** — จัดการหลาย cluster จากที่เดียว

```
┌─────────────────── Argo CD Architecture ───────────────────┐
│                                                            │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐  │
│  │ API Server  │   │  Repo Server │   │ Application     │  │
│  │ (gRPC/REST) │   │ (Git clone)  │   │ Controller      │  │
│  │             │   │              │   │ (Reconcile loop)│  │
│  └──────┬──────┘   └──────┬───────┘   └────────┬────────┘  │
│         │                 │                    │           │
│         │         ┌───────▼───────┐            │           │
│         │         │  Git Repos    │            │           │
│         │         │  (GitHub,     │            │           │
│         │         │   GitLab)     │            │           │
│         │         └───────────────┘            │           │
│         │                                      │           │
│         └──────────────┬───────────────────────┘           │
│                        ▼                                   │
│              ┌─────────────────┐                           │
│              │   Kubernetes    │                           │
│              │   Cluster(s)    │                           │
│              └─────────────────┘                           │
└────────────────────────────────────────────────────────────┘
```

> **หมายเหตุ:** Section นี้เน้น concept + storytelling ก่อน — จะยังไม่ลง command ของ Argo CD จนกว่าจะถึง Day 2

---

### 🎯 Real-world Scenario

**สถานการณ์:** ทีม 5 คน deploy app ทุกวัน มีปัญหา staging กับ production config ต่างกัน ไม่รู้ว่าใคร deploy อะไรเมื่อไหร่

**คำถามให้คิด:**
- ปัจจุบันทีมคุณ deploy อย่างไร? มีปัญหาอะไรบ้าง?
- ถ้ามีคนแก้ cluster ตรง คุณจะรู้ได้อย่างไร?
- ถ้าต้อง rollback ใช้เวลานานแค่ไหน?

---

### 🧪 Lab 1: วาด Pipeline ของทีม

**วัตถุประสงค์:** เข้าใจปัญหาของ pipeline ปัจจุบัน และวางแผนว่า GitOps จะแก้จุดไหน

**ขั้นตอน:**
1. วาด pipeline ของทีมตัวเองบน whiteboard/miro:
   - `code → test → deploy → ปัญหาที่เจอ`
2. ระบุจุดที่มีปัญหา (pain points)
3. วางแผนว่า GitOps จะแก้ที่จุดไหน

---

## Section 2: Kubernetes Fundamentals

`10:45–12:00 (75 นาที) | Hands-on Lab`

### 2.1 Kubernetes คืออะไร?

**Kubernetes (K8s)** คือ container orchestration platform ที่ทำหน้าที่จัดการ containers ในระดับ production:

```
┌──────────────────── Kubernetes Cluster ────────────────────┐
│                                                            │
│  ┌─── Control Plane ───┐    ┌─── Worker Node 1 ───────┐    │
│  │ API Server          │    │  ┌─────┐  ┌─────┐       │    │
│  │ Scheduler           │    │  │ Pod │  │ Pod │       │    │
│  │ Controller Manager  │    │  │ App │  │ App │       │    │
│  │ etcd                │    │  └─────┘  └─────┘       │    │
│  └─────────────────────┘    └─────────────────────────┘    │
│                                                            │
│                              ┌─── Worker Node 2 ───────┐   │
│                              │  ┌─────┐  ┌─────┐       │   │
│                              │  │ Pod │  │ Pod │       │   │
│                              │  │ DB  │  │ App │       │   │
│                              │  └─────┘  └─────┘       │   │
│                              └─────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

---

### 2.2 Core Objects ที่ต้องรู้

| Object         | คำอธิบาย                                                    | เปรียบเทียบ                 |
| -------------- | ----------------------------------------------------------- | --------------------------- |
| **Pod**        | หน่วยเล็กสุดที่รันได้ — ห่อหุ้ม 1+ containers                | = 1 กล่อง container         |
| **Deployment** | จัดการ Pod — กำหนดจำนวน replica, update strategy              | = ผู้จัดการโรงงาน Pod       |
| **Service**    | Endpoint ที่เสถียรสำหรับเข้าถึง Pod (load balancing)          | = หมายเลขโทรศัพท์ที่ไม่เปลี่ยน |
| **Namespace**  | แบ่งขอบเขตทรัพยากรใน cluster                                 | = ห้องแต่ละห้องในอาคาร      |

---

### 2.3 YAML Anatomy — อ่าน YAML ออกก่อน Deploy

ทุก Kubernetes resource ใช้โครงสร้าง YAML เดียวกัน:

```yaml
apiVersion: apps/v1          # เวอร์ชัน API ที่ใช้
kind: Deployment              # ประเภท resource
metadata:                     # ข้อมูลเกี่ยวกับ resource
  name: my-app                # ชื่อ
  namespace: dev               # อยู่ใน namespace ไหน
  labels:                      # ป้ายกำกับ (ใช้สำหรับ filter/select)
    app: my-app
spec:                          # สิ่งที่ต้องการ (desired state)
  replicas: 3                  # จำนวน Pod ที่ต้องการ
  selector:
    matchLabels:
      app: my-app
  template:                    # template สำหรับสร้าง Pod
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: nginx:1.27    # container image ที่ใช้
          ports:
            - containerPort: 80
```

> **สำคัญ:** ทุก YAML มี 4 ส่วนหลัก — `apiVersion`, `kind`, `metadata`, `spec` — จำแค่ 4 อย่างนี้ก็อ่าน YAML ออกแล้ว

---

### 2.4 kubectl Essentials — คำสั่งที่ใช้บ่อย

| คำสั่ง                              | คำอธิบาย                               |
| ----------------------------------- | -------------------------------------- |
| `kubectl apply -f file.yaml`        | สร้าง/อัปเดต resource จากไฟล์ YAML     |
| `kubectl get pods`                  | ดูรายการ Pod ทั้งหมด                   |
| `kubectl get deploy`                | ดูรายการ Deployment                    |
| `kubectl get svc`                   | ดูรายการ Service                       |
| `kubectl describe pod <name>`       | ดูรายละเอียดของ Pod                    |
| `kubectl logs <pod-name>`           | ดู logs ของ Pod                        |
| `kubectl exec -it <pod> -- bash`    | เข้าไปใน Pod (เหมือน SSH)              |
| `kubectl rollout status deploy/xxx` | ดูสถานะ rollout ของ Deployment         |
| `kubectl rollout undo deploy/xxx`   | Rollback Deployment ไป revision ก่อนหน้า |
| `kubectl delete -f file.yaml`       | ลบ resource ที่สร้างจากไฟล์ YAML       |

---

### 2.5 Namespace Strategy — ทำไมต้องแยก

```
┌─────────────── Kubernetes Cluster ───────────────┐
│                                                  │
│  ┌─── dev namespace ───┐  ┌─── staging ────────┐ │
│  │ replicas: 1         │  │ replicas: 2        │ │
│  │ resources: น้อย      │  │ resources: ปานกลาง │ │
│  │ ทดสอบ feature ใหม่  │  │ ทดสอบก่อน prod     │ │
│  └─────────────────────┘  └────────────────────┘ │
│                                                  │
│  ┌─── production namespace ────────────────────┐ │
│  │ replicas: 3                                 │ │
│  │ resources: เต็มกำลัง                          │ │
│  │ มี monitoring, alerting                      │ │
│  └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

```bash
# สร้าง namespace
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# ดู namespace ทั้งหมด
kubectl get namespaces

# deploy ใน namespace ที่ต้องการ
kubectl apply -f deployment.yaml -n dev
```

---

### 2.6 Ingress Concept — Traffic เข้ามายังไง?

```
Internet → Ingress Controller → Service → Pod
              (Nginx/Traefik)    (ClusterIP)
```

- **Ingress** = กฎที่บอกว่า traffic จาก domain ไหน ไปที่ Service ไหน
- ในหลักสูตรนี้เราจะไม่ลงลึก config แต่ให้รู้จักว่า traffic เข้ามายังไง

---

### 🧪 Lab 2: สร้าง Kind Cluster

**วัตถุประสงค์:** สร้าง local Kubernetes cluster ด้วย kind สำหรับใช้ในหลักสูตร

```bash
# ติดตั้ง kind (ถ้ายังไม่มี)
# Windows (PowerShell with admin)
choco install kind

# macOS
brew install kind

# ตรวจสอบ
kind version

# สร้าง cluster จาก config
kind create cluster --config infra/kind/kind-config.yaml --name gitops-workshop

# ตรวจสอบ cluster
kubectl cluster-info
kubectl get nodes
```

ดู config ที่ใช้: [`infra/kind/kind-config.yaml`](../infra/kind/kind-config.yaml)

---

### 🧪 Lab 3: kubectl apply แรก — Deploy Nginx

**วัตถุประสงค์:** ทดลอง deploy application แรกบน Kubernetes

**ขั้นตอนที่ 1:** Apply namespace และ manifests

```bash
# สร้าง namespace ก่อน
kubectl apply -f infra/kubernetes/namespace.yaml

# Deploy Nginx
kubectl apply -f infra/kubernetes/deployment.yaml
kubectl apply -f infra/kubernetes/service.yaml
```

ดูไฟล์ manifests ที่:
- [`infra/kubernetes/namespace.yaml`](../infra/kubernetes/namespace.yaml)
- [`infra/kubernetes/deployment.yaml`](../infra/kubernetes/deployment.yaml)
- [`infra/kubernetes/service.yaml`](../infra/kubernetes/service.yaml)

**ขั้นตอนที่ 2:** ตรวจสอบผลลัพธ์

```bash
# ตรวจสอบ
kubectl get pods -n dev
kubectl get svc -n dev
kubectl describe deployment nginx-demo -n dev

# เข้าถึงจาก browser
# http://localhost:30080
```

---

### 🧪 Lab 4: ทดลอง Rollback ด้วย kubectl

**วัตถุประสงค์:** เข้าใจว่า Kubernetes built-in rollback ทำงานอย่างไร ก่อนที่ Argo CD จะ manage ให้

```bash
# เปลี่ยน image เป็น version ใหม่
kubectl set image deployment/nginx-demo nginx=nginx:1.28-alpine -n dev

# ดูสถานะ rollout
kubectl rollout status deployment/nginx-demo -n dev

# ดูประวัติ revision
kubectl rollout history deployment/nginx-demo -n dev

# Rollback ไป version ก่อนหน้า
kubectl rollout undo deployment/nginx-demo -n dev

# ยืนยันว่ากลับเป็น version เดิม
kubectl get pods -o wide -n dev
kubectl describe deployment nginx-demo -n dev | grep Image
```

> **คำถามชวนคิด:** ถ้าทีมมี 10 คน แต่ละคน rollout undo คนละเวลา — จะรู้ได้ไงว่า production ตอนนี้เป็น version อะไร?

---

### สรุป Section 1 & 2

| หัวข้อ | สิ่งที่ได้เรียนรู้ |
|---|---|
| **S1: GitOps Concept** | Pain Point ของ Push-based · 4 หลักการ GitOps · Pull-based แก้ปัญหาอย่างไร |
| **S2: Kubernetes** | Pod · Deployment · Service · Namespace · kubectl essentials · YAML anatomy |

> **ต่อไป:** [Section 3 & 4 → CI/CD Pipeline + GitOps Basic Flow](02-cicd-github-actions.md)
