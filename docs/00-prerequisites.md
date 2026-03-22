# สิ่งที่ต้องเตรียมก่อน Workshop

> **Workshop:** GitOps with Argo CD (2026 Edition)  
> **กรุณาเตรียมพร้อมก่อนวันอบรม** เพื่อให้เวลา hands-on เต็มที่

---

## 1. Hardware & Software Requirements

| รายการ      | ความต้องการขั้นต่ำ         | แนะนำ                 |
|-------------|----------------------------|-----------------------|
| **OS**      | Windows 10/11, macOS 12+, Ubuntu 20.04+ | macOS / Linux |
| **RAM**     | 8 GB (cluster + host)     | 16 GB                 |
| **CPU**     | 4 cores                   | 8 cores               |
| **Disk**    | 20 GB ว่าง                | 40 GB SSD             |
| **Network** | Internet connection        | Stable broadband      |

---

## 2. Software ที่ต้องติดตั้ง (ทุกคน)

### 2.1 Docker Desktop

ดาวน์โหลด: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

```bash
# ตรวจสอบหลังติดตั้ง
docker --version
# Docker version 24.x.x หรือสูงกว่า
```

### 2.2 kubectl

```bash
# macOS (Homebrew)
brew install kubectl

# Windows (Chocolatey)
choco install kubernetes-cli

# ตรวจสอบ
kubectl version --client
```

### 2.3 kind (Kubernetes in Docker)

ดาวน์โหลด: [https://kind.sigs.k8s.io/docs/user/quick-start/#installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

```bash
# macOS
brew install kind

# Windows
choco install kind

# ตรวจสอบ
kind version
# kind v0.22+ แนะนำ
```

### 2.4 Git

```bash
# ตรวจสอบ
git --version
# git version 2.x.x

# ตั้งค่า (ถ้ายังไม่ได้ทำ)
git config --global user.name "ชื่อ-นามสกุล"
git config --global user.email "your@email.com"
```

### 2.5 Text Editor / IDE

- **VS Code** (แนะนำ): [https://code.visualstudio.com/](https://code.visualstudio.com/)
  - Extension ที่แนะนำ: `YAML`, `Kubernetes`, `GitLens`
- Vim, Nano หรือ Editor ที่ถนัด

---

## 3. GitHub Account

1. สร้าง account ที่ [https://github.com](https://github.com) (ถ้ายังไม่มี)
2. **สร้าง Personal Access Token (PAT):**
   - Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Scopes ที่ต้องการ: `write:packages`, `read:packages`, `delete:packages`
   - บันทึก token ไว้ใช้ใน Lab

3. **Fork repo ของ workshop:**
   > https://github.com/iamsamitdev/gitops-workshop-cmu

---

## 4. ตรวจสอบความพร้อม (Pre-flight Check)

รันคำสั่งต่อไปนี้เพื่อตรวจสอบว่าทุกอย่างพร้อม:

```bash
# ตรวจสอบทุกอย่างในคำสั่งเดียว
echo "=== Pre-flight Check ===" && \
echo "Docker:  $(docker --version)" && \
echo "kubectl: $(kubectl version --client --short 2>/dev/null)" && \
echo "kind:    $(kind version)" && \
echo "git:     $(git --version)" && \
echo "=== ✅ พร้อมเริ่ม Workshop! ==="
```

---

## 5. Kubernetes Prerequisites

**ไม่จำเป็นต้องมี Kubernetes cluster มาก่อน** — เราจะสร้างด้วยกันใน Workshop

แต่ถ้าอยากลองมาก่อน:

```bash
# ทดสอบสร้าง cluster
kind create cluster --name test
kubectl get nodes
kind delete cluster --name test
```

---

## 6. ความรู้พื้นฐานที่ควรมี

| ระดับ | ทักษะ |
|-------|-------|
| ✅ **จำเป็น** | Linux CLI: `ls`, `cat`, `curl`, `export` |
| ✅ **จำเป็น** | Git basics: `clone`, `commit`, `push`, `branch` |
| ✅ **จำเป็น** | Docker: รู้จัก image และ container เบื้องต้น |
| 🔵 **มีก็ดี** | YAML syntax |
| 🔵 **มีก็ดี** | ทราบว่า Kubernetes คืออะไร |

---

## 7. ลิงก์ทรัพยากรที่ใช้ใน Workshop

| ทรัพยากร | URL |
|---|---|
| เอกสารการอบรม | [https://bit.ly/gitops-cmu](https://bit.ly/gitops-cmu) |
| Workshop Repository | [https://github.com/iamsamitdev/gitops-workshop-cmu](https://github.com/iamsamitdev/gitops-workshop-cmu) |
| Argo CD Docs | [https://argo-cd.readthedocs.io/](https://argo-cd.readthedocs.io/) |
| Kustomize Docs | [https://kustomize.io/](https://kustomize.io/) |
| Kind Docs | [https://kind.sigs.k8s.io/](https://kind.sigs.k8s.io/) |

---

> **มีปัญหา?** ติดต่อวิทยากร: อาจารย์สามิตร โกยม | IT Genius Institute
