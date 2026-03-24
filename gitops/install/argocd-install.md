# ติดตั้ง Argo CD — คู่มือ Section 5

> **Lab:** S5 — Argo CD Deep Dive  
> **เวลา:** 09:00–10:30 (90 นาที)

---

## ขั้นตอนที่ 1: สร้าง Namespace และติดตั้ง Argo CD

```bash
# 1. สร้าง namespace สำหรับ Argo CD
kubectl create namespace argocd

# 2. ติดตั้ง Argo CD (stable release)
# ⚠️  ต้องใช้ --server-side เพื่อหลีกเลี่ยง error:
#    "metadata.annotations: Too long: may not be more than 262144 bytes"
#    (CRD ของ Argo CD ใหม่ใหญ่เกิน 256KB limit ของ annotation แบบ client-side apply)
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side

# 3. รอจน pod ทั้งหมดพร้อม (ใช้เวลาประมาณ 2-3 นาที)
kubectl get pods -n argocd -w
```

> **หมายเหตุ:** ถ้ารัน `kubectl apply` แบบปกติไปก่อนแล้ว (มี conflict) ให้เพิ่ม `--force-conflicts`:
> ```bash
> kubectl apply -n argocd \
>   -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
>   --server-side --force-conflicts
> ```


**Pods ที่ควรเห็น:**

```
NAME                                                READY   STATUS    RESTARTS
argocd-application-controller-0                     1/1     Running   0
argocd-applicationset-controller-xxx                1/1     Running   0
argocd-dex-server-xxx                               1/1     Running   0
argocd-notifications-controller-xxx                 1/1     Running   0
argocd-redis-xxx                                    1/1     Running   0
argocd-repo-server-xxx                              1/1     Running   0
argocd-server-xxx                                   1/1     Running   0
```

---

## ขั้นตอนที่ 2: เข้าถึง Argo CD UI

```bash
# Port-forward เพื่อเข้า UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# ดู initial admin password (รันในอีก terminal)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

เปิด browser: **https://localhost:8080**

| ข้อมูล login | ค่า |
| --- | --- |
| Username | `admin` |
| Password | (จากคำสั่งด้านบน) |

---

## ขั้นตอนที่ 3: ติดตั้ง Argo CD CLI

```bash
# macOS (Homebrew)
brew install argocd

# Linux (AMD64)
curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Windows (PowerShell — ใช้ winget)
winget install --id argoproj.argocd --source winget

# ตรวจสอบ version
argocd version --client
```

---

## ขั้นตอนที่ 4: Login ผ่าน Argo CD CLI

```bash
# Login (ใช้กับ port-forward ที่รันอยู่)
argocd login localhost:8080 \
  --username admin \
  --password <password-จาก-step-2> \
  --insecure

# ตรวจสอบ: ดูรายการ app (ควรจะว่างเปล่าในตอนแรก)
argocd app list
```

---

## ขั้นตอนที่ 5: สร้าง Application แรก

ดูตัวอย่างไฟล์ Application YAML ได้ที่ `gitops/applications/app-dev.yaml`

```bash
# apply Application จาก gitops layer
kubectl apply -f gitops/applications/app-dev.yaml

# ตรวจสอบสถานะ
argocd app get my-app-dev
argocd app list
```

---

## คำสั่งที่ใช้บ่อย

```bash
# ดูสถานะ apps ทั้งหมด
argocd app list

# ดูรายละเอียด app
argocd app get <app-name>

# Sync app ด้วยมือ
argocd app sync <app-name>

# ดูประวัติ revision
argocd app history <app-name>

# Rollback ไป revision N
argocd app rollback <app-name> <N>

# ดู logs ของ sync operation
argocd app logs <app-name>
```

---

## หมายเหตุ

- Argo CD สแกน Git ทุก **3 นาที** (default) หรือเมื่อมี webhook จาก GitHub
- ถ้าต้องการเปลี่ยน sync interval แก้ที่ `argocd-cm` ConfigMap
- ใน production ควรใช้ **Ingress** แทน port-forward สำหรับการเข้าถึง UI
- ใช้ `--server-side` ทุกครั้งที่ install — หลีกเลี่ยง CRD annotation size error

---

> **ต่อไป:** ดูการตั้งค่า Application YAML ได้ที่ `gitops/applications/`
