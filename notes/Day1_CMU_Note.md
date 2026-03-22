## Workshop: GitOps with Argo CD — Day 1

## Foundation: DevOps → GitOps → Kubernetes → CI/CD Flow

### Download Training Document

[Click here to download the training document](https://bit.ly/gitops-cmu)

---

### บทนำ (Introduction)

หลักสูตร **GitOps with Argo CD** ฉบับปรับปรุง 2026 ออกแบบมาเพื่อให้ผู้เรียนเข้าใจและนำ **GitOps** มาใช้งานจริงด้วย **Argo CD** ซึ่งเป็น **CNCF Graduated Project** สำหรับ Kubernetes Continuous Delivery แบบ Pull-based ที่ทำให้ cluster state สอดคล้องกับ Git repository โดยอัตโนมัติตลอดเวลา

ในยุค **Cloud Native** และ **Platform Engineering** การส่งมอบซอฟต์แวร์อย่างรวดเร็ว ปลอดภัย และสามารถ reproduce ได้ คือหัวใจสำคัญขององค์กร หลักสูตร 2 วันนี้จะพาผู้เรียนจากพื้นฐาน DevOps ไปจนถึง production-ready GitOps pipeline ด้วย Argo CD

---

### สถาบันผู้จัดอบรม

| รายละเอียด  | ข้อมูล                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------- |
| สถานที่อบรม | [สำนักบริการเทคโนโลยีสารสนเทศ มหาวิทยาลัยเชียงใหม่ (ITSC CMU)](https://www.itsc.cmu.ac.th/) |
| วิทยากร     | อาจารย์สามิตร โกยม                                                                          |
| สถาบัน      | สถาบันไอทีจีเนียส (IT Genius)                                                               |
| ระยะเวลา    | 12 ชั่วโมง (2 วัน)                                                                          |
| รูปแบบ      | Concept + Visual Flow 30% · Hands-on Lab 70%                                                |
| เวอร์ชัน    | Argo CD v2.x · Kubernetes 1.29+ · Kustomize v5 · GitHub Actions                            |

---

### วัตถุประสงค์ของหลักสูตร (Objectives)

1. เข้าใจหลักการ GitOps, Pull-based deployment และสถาปัตยกรรมของ Argo CD v2.x อย่างลึกซึ้ง
2. ติดตั้งและตั้งค่า Argo CD บน Kubernetes ได้อย่างถูกต้อง ทั้งแบบ single-cluster และ multi-cluster
3. สร้างและจัดการ Application, AppProject และ ApplicationSet ทั้งผ่าน UI, CLI และ YAML declarative
4. ใช้งาน Helm Charts และ Kustomize ร่วมกับ Argo CD สำหรับ multi-environment configuration
5. ตั้งค่า Sync Policies, Sync Waves, Resource Hooks และ Health Checks อย่างมืออาชีพ
6. จัดการ Secrets อย่างปลอดภัยด้วย Sealed Secrets และ Argo CD Vault Plugin
7. ตั้งค่า SSO, RBAC และ AppProject เพื่อ Multi-tenancy ในระดับ enterprise
8. ออกแบบ CI/CD pipeline แบบครบวงจรและทำ Progressive Delivery ด้วย Argo Rollouts

---

### จุดเด่นของหลักสูตร (Highlights)

- 🔧 **Hands-on 70%** — ทุก section มี Lab จริง ลงมือทำตั้งแต่ติดตั้งจนถึง production-ready pipeline
- 📅 **เนื้อหา up-to-date 2026** — ครอบคลุม Argo CD v2.x, ApplicationSet, Argo Rollouts, Sealed Secrets
- 🔒 **GitOps Security** — เรียนรู้การจัดการ Secrets, RBAC, SSO และ image provenance ที่ปลอดภัย
- 🌐 **Multi-cluster & Multi-tenant** — ออกแบบ pipeline สำหรับหลาย environment และหลายทีม
- ⚙️ **CI/CD Integration** — เชื่อมต่อ GitHub Actions เพื่อ update image tag และ trigger sync อัตโนมัติ
- 🚀 **Progressive Delivery** — ทำ Canary และ Blue-Green deployment ด้วย Argo Rollouts

---

### กลุ่มเป้าหมาย (Target Audience)

- **DevOps Engineers / Platform Engineers / SRE** ที่ต้องการนำ GitOps มาใช้จริง
- **Cloud Engineers / System Administrators** ที่ดูแล Kubernetes cluster
- **Software Developers** ที่ต้องการเข้าใจกระบวนการ deploy application สมัยใหม่
- **ผู้ที่ต้องการนำ GitOps มาใช้ในองค์กร** และต้องการ best practice ที่นำไปใช้ได้ทันที

---

### ผู้เรียนต้องมีพื้นฐานอะไรบ้าง (Prerequisites)

- ✅ **Linux CLI** — `ls`, `cat`, `curl`, `export`, `ssh` เบื้องต้น
- ✅ **Git** — `clone`, `commit`, `push`, `branch`, pull request
- ✅ **Docker** — รู้จัก image และ container เบื้องต้น
- ✅ **อุปกรณ์** — Laptop (Windows / macOS / Linux) เชื่อมต่ออินเทอร์เน็ต

---

### เนื้อหาการอบรม (Course Outline)

**วันที่ 1: Foundation — DevOps → GitOps → Kubernetes → CI/CD Flow**

1. [Section 1: DevOps → GitOps: ทำไมต้องเปลี่ยน?](#section-1-devops--gitops-ทำไมต้องเปลี่ยน)
   - Pain Point จริงของ Traditional CI/CD
   - GitOps 4 หลักการ: Declarative, Versioned, Automated, Continuously Reconciled
   - Push-based vs Pull-based — Visual เปรียบเทียบ
   - Argo CD Architecture Overview

2. [Section 2: Kubernetes Fundamentals](#section-2-kubernetes-fundamentals)
   - Core Objects: Pod, Deployment, Service, Namespace
   - kubectl Essentials
   - Namespace Strategy: dev / staging / production
   - YAML Anatomy & Ingress Concept

3. [Section 3: CI/CD Pipeline with GitHub Actions](#section-3-cicd-pipeline-with-github-actions)
   - GitHub Actions Anatomy: trigger, job, step, runner
   - Build Docker Image & Push to GHCR
   - Image Tagging Strategy
   - CI Pipeline: code → build → test → push image

4. [Section 4: GitOps Basic Flow — Bridge to Argo CD](#section-4-gitops-basic-flow--bridge-to-argo-cd)
   - Git as Single Source of Truth
   - Declarative vs Imperative
   - Manifest Repo: แยก app code กับ config
   - Manual GitOps Flow → ทำไมต้องมี Argo CD

**วันที่ 2: Argo CD Deep Dive, Kustomize, Production Design & End-to-End**

5. [Section 5: Argo CD Deep Dive](#section-5-argo-cd-deep-dive)
6. [Section 6: Kustomize Multi-environment + Helm Overview](#section-6-kustomize-multi-environment--helm-overview)
7. [Section 7: Production Design — Git Structure, RBAC & Secrets](#section-7-production-design--git-structure-rbac--secrets)
8. [Section 8: Best Practices + Final End-to-End Workshop](#section-8-best-practices--final-end-to-end-workshop)

---

### ตารางเวลา — วันที่ 1: Foundation

| Section | เวลา        | หัวข้อ                                      | รูปแบบ        | หมายเหตุ                          |
| ------- | ----------- | ------------------------------------------- | ------------- | --------------------------------- |
| S1      | 09:00–10:30 | DevOps → GitOps: Pain Point + Visual Concept | Concept+Visual | 90 นาที — storytelling ก่อน command |
| —       | 10:30–10:45 | พักเบรก                                     | —             |                                   |
| S2      | 10:45–12:00 | Kubernetes Fundamentals                      | Lab           | 75 นาที — พื้นฐานที่ขาดไม่ได้     |
| —       | 12:00–13:00 | พักรับประทานอาหาร                           | —             |                                   |
| S3      | 13:00–14:15 | CI/CD Pipeline — GitHub Actions              | Lab           | 75 นาที — 1 tool, เน้น flow       |
| —       | 14:15–14:30 | พักเบรก                                     | —             |                                   |
| S4      | 14:30–16:00 | GitOps Basic Flow — Bridge to Argo CD        | Lab           | 90 นาที — manual gitops → why ArgoCD |

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

### 1.2 Traditional CI/CD — Push-based Model

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐
│   Dev    │───▶│  CI/CD   │───▶│  Build   │───▶│   kubectl    │
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

### 1.3 GitOps แก้ปัญหาอย่างไร?

**GitOps** คือวิธีปฏิบัติที่ใช้ **Git เป็น single source of truth** สำหรับ infrastructure และ application:

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│   Dev    │───▶│   Git    │◀──▶│ Argo CD  │
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

### 1.4 GitOps 4 หลักการ (Principles)

GitOps ถูกนิยามโดย **OpenGitOps** (CNCF Sandbox) ด้วย 4 หลักการ:

| หลักการ                      | คำอธิบาย                                                      |
| ---------------------------- | ------------------------------------------------------------- |
| **1. Declarative**           | ระบบทั้งหมดต้องอธิบายได้ด้วย declaration (YAML/JSON)            |
| **2. Versioned & Immutable** | desired state ถูกเก็บใน Git — มี version, ย้อนกลับได้, tamper-proof |
| **3. Pulled Automatically**  | agent (Argo CD) ดึง desired state จาก Git มา apply อัตโนมัติ    |
| **4. Continuously Reconciled** | agent เฝ้า reconcile ตลอดเวลา — ถ้า actual ≠ desired → แก้ไข  |

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

### 1.6 Argo CD คืออะไร?

**Argo CD** คือ declarative, GitOps continuous delivery tool สำหรับ Kubernetes:

- 🎓 **CNCF Graduated Project** — ผ่านการรับรองว่า production-ready
- 🔄 **Pull-based** — ดึง desired state จาก Git มา sync ตลอดเวลา
- 🖥️ **มี Web UI** — เห็น application status แบบ real-time
- 🔧 **รองรับหลาย config tool** — Plain YAML, Kustomize, Helm, Jsonnet
- 🏢 **Multi-cluster** — จัดการหลาย cluster จากที่เดียว

```
┌─────────────────── Argo CD Architecture ───────────────────┐
│                                                             │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐  │
│  │ API Server  │   │  Repo Server │   │ Application     │  │
│  │ (gRPC/REST) │   │ (Git clone)  │   │ Controller      │  │
│  │             │   │              │   │ (Reconcile loop)│  │
│  └──────┬──────┘   └──────┬───────┘   └────────┬────────┘  │
│         │                 │                     │           │
│         │         ┌───────▼───────┐              │           │
│         │         │  Git Repos    │              │           │
│         │         │  (GitHub,     │              │           │
│         │         │   GitLab)     │              │           │
│         │         └───────────────┘              │           │
│         │                                       │           │
│         └──────────────┬────────────────────────┘           │
│                        ▼                                    │
│              ┌─────────────────┐                            │
│              │   Kubernetes    │                            │
│              │   Cluster(s)   │                            │
│              └─────────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

> **หมายเหตุ:** Section นี้เน้น concept + storytelling ก่อน — จะยังไม่ลง command ของ Argo CD จนกว่าจะถึง Day 2

### 🎯 Real-world Scenario

**สถานการณ์:** ทีม 5 คน deploy app ทุกวัน มีปัญหา staging กับ production config ต่างกัน ไม่รู้ว่าใคร deploy อะไรเมื่อไหร่

**คำถามให้คิด:**
- ปัจจุบันทีมคุณ deploy อย่างไร? มีปัญหาอะไรบ้าง?
- ถ้ามีคนแก้ cluster ตรง คุณจะรู้ได้อย่างไร?
- ถ้าต้อง rollback ใช้เวลานานแค่ไหน?

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
│                                                             │
│  ┌─── Control Plane ───┐    ┌─── Worker Node 1 ────────┐   │
│  │ API Server           │    │  ┌─────┐  ┌─────┐       │   │
│  │ Scheduler            │    │  │ Pod │  │ Pod │       │   │
│  │ Controller Manager   │    │  │ App │  │ App │       │   │
│  │ etcd                │    │  └─────┘  └─────┘       │   │
│  └──────────────────────┘    └──────────────────────────┘   │
│                                                             │
│                              ┌─── Worker Node 2 ────────┐   │
│                              │  ┌─────┐  ┌─────┐       │   │
│                              │  │ Pod │  │ Pod │       │   │
│                              │  │ DB  │  │ App │       │   │
│                              │  └─────┘  └─────┘       │   │
│                              └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Core Objects ที่ต้องรู้

| Object         | คำอธิบาย                                                    | เปรียบเทียบ                 |
| -------------- | ----------------------------------------------------------- | --------------------------- |
| **Pod**        | หน่วยเล็กสุดที่รันได้ — ห่อหุ้ม 1+ containers                | = 1 กล่อง container         |
| **Deployment** | จัดการ Pod — กำหนดจำนวน replica, update strategy              | = ผู้จัดการโรงงาน Pod       |
| **Service**    | Endpoint ที่เสถียรสำหรับเข้าถึง Pod (load balancing)          | = หมายเลขโทรศัพท์ที่ไม่เปลี่ยน |
| **Namespace**  | แบ่งขอบเขตทรัพยากรใน cluster                                 | = ห้องแต่ละห้องในอาคาร      |

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

### 2.5 Namespace Strategy — ทำไมต้องแยก

```
┌─────────────── Kubernetes Cluster ───────────────┐
│                                                   │
│  ┌─── dev namespace ───┐  ┌─── staging ────────┐  │
│  │ replicas: 1          │  │ replicas: 2         │  │
│  │ resources: น้อย       │  │ resources: ปานกลาง  │  │
│  │ ทดสอบ feature ใหม่    │  │ ทดสอบก่อน prod      │  │
│  └──────────────────────┘  └─────────────────────┘  │
│                                                   │
│  ┌─── production namespace ─────────────────────┐  │
│  │ replicas: 3                                   │  │
│  │ resources: เต็มกำลัง                          │  │
│  │ มี monitoring, alerting                       │  │
│  └───────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────┘
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

### 2.6 Ingress Concept — Traffic เข้ามายังไง?

```
Internet → Ingress Controller → Service → Pod
              (Nginx/Traefik)    (ClusterIP)
```

- **Ingress** = กฎที่บอกว่า traffic จาก domain ไหน ไปที่ Service ไหน
- ในหลักสูตรนี้เราจะไม่ลงลึก config แต่ให้รู้จักว่า traffic เข้ามายังไง

### 🧪 Lab 2: kubectl apply แรก — Deploy Nginx

**วัตถุประสงค์:** ทดลอง deploy application แรกบน Kubernetes

**ขั้นตอนที่ 1:** สร้างไฟล์ `nginx-deployment.yaml`

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  labels:
    app: nginx-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
```

**ขั้นตอนที่ 2:** สร้างไฟล์ `nginx-service.yaml`

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
spec:
  type: NodePort
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

**ขั้นตอนที่ 3:** Deploy และตรวจสอบ

```bash
# Deploy
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

# ตรวจสอบ
kubectl get pods
kubectl get svc
kubectl describe deployment nginx-demo

# เข้าถึงจาก browser
# http://localhost:30080
```

### 🧪 Lab 3: ทดลอง Rollback ด้วย kubectl

**วัตถุประสงค์:** เข้าใจว่า Kubernetes built-in rollback ทำงานอย่างไร ก่อนที่ Argo CD จะ manage ให้

```bash
# เปลี่ยน image เป็น version ใหม่
kubectl set image deployment/nginx-demo nginx=nginx:1.28-alpine

# ดูสถานะ rollout
kubectl rollout status deployment/nginx-demo

# ดูประวัติ revision
kubectl rollout history deployment/nginx-demo

# Rollback ไป version ก่อนหน้า
kubectl rollout undo deployment/nginx-demo

# ยืนยันว่ากลับเป็น version เดิม
kubectl get pods -o wide
kubectl describe deployment nginx-demo | grep Image
```

> **คำถามชวนคิด:** ถ้าทีมมี 10 คน แต่ละคน rollout undo คนละเวลา — จะรู้ได้ไงว่า production ตอนนี้เป็น version อะไร?

---

## Section 3: CI/CD Pipeline with GitHub Actions

`13:00–14:15 (75 นาที) | Hands-on Lab`

### 3.1 GitHub Actions คืออะไร?

**GitHub Actions** คือ CI/CD platform ของ GitHub ที่ให้เรา automate workflow ได้ตรงบน repository:

```
┌────────────────── GitHub Actions Workflow ──────────────────┐
│                                                              │
│  Trigger (Event)         Job                    Steps        │
│  ┌──────────────┐   ┌──────────────┐   ┌─────────────────┐  │
│  │ push to main │──▶│ build-and-   │──▶│ 1. Checkout     │  │
│  │ pull_request │   │ push         │   │ 2. Login GHCR   │  │
│  │ manual       │   │              │   │ 3. Build image  │  │
│  └──────────────┘   │ runs-on:     │   │ 4. Push image   │  │
│                     │ ubuntu-latest │   └─────────────────┘  │
│                     └──────────────┘                         │
└──────────────────────────────────────────────────────────────┘
```

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

### 3.3 Dockerfile Basics

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

### 3.4 Container Registry — GHCR

**GitHub Container Registry (GHCR)** เป็น container registry ที่ใช้ได้ทันทีกับ GitHub Account:

| Registry   | URL                    | ข้อดี                        |
| ---------- | ---------------------- | ---------------------------- |
| **GHCR**   | `ghcr.io/username/app` | ใช้ได้ทันที, ผูกกับ GitHub     |
| Docker Hub | `docker.io/user/app`   | นิยมมากสุด, มี rate limit     |
| ECR        | `xxx.ecr.region.amazonaws.com` | สำหรับ AWS               |
| GCR/GAR    | `gcr.io/project/app`  | สำหรับ GCP                   |

### 3.5 Image Tagging Strategy — ทำไม latest ไม่ควรใช้ใน Production

| Strategy             | ตัวอย่าง             | ข้อดี                         | ข้อเสีย                   |
| -------------------- | -------------------- | ----------------------------- | ------------------------- |
| **latest** ❌         | `my-app:latest`      | สะดวก                         | ไม่รู้ว่า version อะไร, ไม่ reproducible |
| **Git SHA** ✅        | `my-app:a1b2c3d`     | ตรงกับ commit, reproducible   | อ่านยาก                   |
| **Semantic Version** ✅ | `my-app:v1.2.3`     | อ่านง่าย, major/minor/patch   | ต้อง manage version เอง   |
| **Git SHA + SemVer** ✅ | `my-app:v1.2.3-a1b2c3d` | ดีที่สุด — อ่านง่าย + traceable | ยาวหน่อย               |

> **Best Practice:** ใช้ **Git SHA** หรือ **Semantic Version** เสมอ — `latest` ไม่ควรใช้ใน production เพราะ Kubernetes จะไม่ pull image ใหม่ถ้า tag ไม่เปลี่ยน

### 🧪 Lab 4: สร้าง GitHub Actions CI Pipeline

**วัตถุประสงค์:** สร้าง CI pipeline ที่ build Docker image แล้ว push ไป GHCR

**ขั้นตอนที่ 1:** สร้างไฟล์ `.github/workflows/ci.yml`

```yaml
# .github/workflows/ci.yml
name: CI - Build and Push Docker Image

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=raw,value=latest

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

**ขั้นตอนที่ 2:** Push code แล้วดู Actions tab

```bash
git add .
git commit -m "feat: add CI pipeline"
git push origin main
```

### 🧪 Lab 5: ตรวจสอบ Image ใน GHCR

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
│                                                       │
│   "สิ่งที่อยู่ใน Git = สิ่งที่ควรอยู่ใน Cluster"         │
│                                                       │
│   Git Repo (desired state)   Cluster (actual state)   │
│   ┌────────────────────┐    ┌────────────────────┐    │
│   │ deployment.yaml    │ =? │ Deployment         │    │
│   │   image: v1.2.3    │    │   image: v1.2.3    │    │
│   │   replicas: 3      │    │   replicas: 3      │    │
│   └────────────────────┘    └────────────────────┘    │
│                                                       │
│   ถ้าเท่ากัน  →  ✅ Synced (สถานะปกติ)               │
│   ถ้าไม่เท่า  →  ⚠️ OutOfSync (ต้อง sync)            │
└───────────────────────────────────────────────────────┘
```

### 4.2 Declarative vs Imperative

| แบบ              | ตัวอย่าง                                    | ข้อดี                              | ข้อเสีย                        |
| ---------------- | ------------------------------------------- | ---------------------------------- | ------------------------------ |
| **Imperative** ❌ | `kubectl run nginx --image=nginx`           | สะดวก, เร็ว                        | ไม่มี record, reproduce ไม่ได้ |
| **Declarative** ✅ | `kubectl apply -f deployment.yaml`         | มี YAML = มี record, reproduce ได้ | ต้องเขียน YAML                 |

> **GitOps Rule:** ทุกอย่างต้องเป็น **Declarative** — ถ้าไม่มีใน Git ก็ไม่ควรอยู่ใน Cluster

### 4.3 Manifest Repo — ทำไมต้องแยก App Code กับ Config

```
┌─── App Repo ───────────────┐    ┌─── Manifest Repo ────────────┐
│ (Source Code + Dockerfile)  │    │ (Kubernetes YAML configs)     │
│                             │    │                               │
│ src/                        │    │ base/                         │
│   index.js                  │    │   deployment.yaml             │
│   ...                       │    │   service.yaml                │
│ Dockerfile                  │    │   kustomization.yaml          │
│ .github/workflows/ci.yml   │    │ overlays/                     │
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

### 🧪 Lab 6: สร้าง Manifest Repo

**วัตถุประสงค์:** สร้าง manifest repo แยกจาก app repo สำหรับ GitOps

**ขั้นตอนที่ 1:** สร้าง repo ใหม่บน GitHub ชื่อ `my-app-manifests`

**ขั้นตอนที่ 2:** สร้าง `deployment.yaml`

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 2
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
          image: ghcr.io/<username>/my-app:latest  # จะเปลี่ยนเป็น git SHA ที่หลัง
          ports:
            - containerPort: 3000
```

**ขั้นตอนที่ 3:** สร้าง `service.yaml`

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 3000
      nodePort: 30080
```

**ขั้นตอนที่ 4:** สร้าง `kustomization.yaml`

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

**ขั้นตอนที่ 5:** Push ไป GitHub

```bash
git init
git add .
git commit -m "init: add Kubernetes manifests"
git remote add origin https://github.com/<username>/my-app-manifests.git
git push -u origin main
```

### 🧪 Lab 7: Manual GitOps — แก้ Image Tag แล้ว Apply ด้วยมือ

**วัตถุประสงค์:** ทำ GitOps ด้วยมือ (manual) เพื่อเห็นปัญหาถ้าไม่มี automation

**ขั้นตอนที่ 1:** แก้ image tag ใน `deployment.yaml`

```yaml
# เปลี่ยนจาก
image: ghcr.io/<username>/my-app:latest
# เป็น
image: ghcr.io/<username>/my-app:<new-sha>
```

**ขั้นตอนที่ 2:** Commit & push

```bash
git add deployment.yaml
git commit -m "deploy: update image to <new-sha>"
git push origin main
```

**ขั้นตอนที่ 3:** Apply ด้วยมือ

```bash
kubectl apply -k .
kubectl get pods
kubectl rollout status deployment/my-app
```

**ขั้นตอนที่ 4:** สังเกต state เปลี่ยน

```bash
kubectl get pods -w  # watch pods เปลี่ยน
```

### 🧪 Lab 8: ตั้งคำถาม — ทำไมต้อง Argo CD?

**คำถามให้คิด:**
- ถ้าต้องทำ Lab 7 ทุกครั้งที่มี commit ใหม่ มีปัญหาอะไร?
- ถ้ามีคน `kubectl apply` version ผิด จะรู้ได้อย่างไร?
- ถ้ามีคนลบ Deployment ตรงจาก cluster ใครจะฟื้นให้?
- ถ้ามี 10 environments ต้อง apply ทุก env ทีละ command?

> **คำตอบ:** Argo CD จะทำ kubectl apply ให้อัตโนมัติ ตรวจจับ drift ได้ และ self-heal เมื่อมีคนแก้ cluster ตรง — ซึ่งเราจะเรียนกันใน Day 2!

### 4.4 End-to-End Flow — สิ่งที่เราทำได้ใน Day 1

```
┌──────────────────── Day 1 End-to-End Flow ────────────────────┐
│                                                                │
│  1. Code         2. GitHub Actions      3. GHCR               │
│  ┌────────┐     ┌────────────────┐     ┌──────────────┐       │
│  │ git    │────▶│ build image    │────▶│ push image   │       │
│  │ push   │     │ tag: git SHA   │     │ ghcr.io/...  │       │
│  └────────┘     └────────────────┘     └──────┬───────┘       │
│                                                │               │
│  4. Update Manifest   5. kubectl apply (Manual)│               │
│  ┌────────────────┐   ┌────────────────┐       │               │
│  │ แก้ image tag  │──▶│ kubectl apply  │◀──────┘               │
│  │ ใน manifest    │   │ -k . (ด้วยมือ) │                       │
│  │ repo + commit  │   └───────┬────────┘                       │
│  └────────────────┘           │                                │
│                               ▼                                │
│                        ┌──────────────┐                        │
│                        │  Kubernetes  │                        │
│                        │  Cluster     │                        │
│                        └──────────────┘                        │
│                                                                │
│  Day 2: Argo CD จะแทน step 5 (kubectl apply ด้วยมือ)           │
│         ให้เป็นอัตโนมัติ + self-heal + drift detection!       │
└────────────────────────────────────────────────────────────────┘
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

เทคนิคทั้งหมดจาก Day 1 เป็นพื้นฐานสำคัญสำหรับ **Day 2** ที่จะเจาะลึก Argo CD Deep Dive, Kustomize Multi-environment, Production Design (RBAC, Secrets) และ Final End-to-End Workshop ที่ผู้เรียนจะทำ pipeline สมบูรณ์ด้วยตัวเอง
