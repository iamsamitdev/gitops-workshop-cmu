# Sealed Secrets — คู่มือการใช้งาน

> **Lab:** S7 — Production Design: Secrets Management  
> **Project:** [bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)

---

## ทำไมต้อง Sealed Secrets?

| ปัญหา | วิธีแก้ |
| --- | --- |
| Kubernetes Secret เป็นแค่ base64 — ไม่ได้ encrypt | ใช้ Sealed Secrets encrypt ด้วย asymmetric key |
| ไม่สามารถ commit Secret ปกติลง Git ได้ (unsafe) | `SealedSecret` สามารถ commit ลง Git ได้อย่างปลอดภัย |
| ต้องการ GitOps workflow สำหรับ secrets ด้วย | Argo CD deploy `SealedSecret` → controller decrypt → `Secret` |

---

## ขั้นตอนที่ 1: ติดตั้ง Sealed Secrets Controller

```bash
# ติดตั้ง controller ใน cluster
kubectl apply -f \
  https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.0/controller.yaml

# ตรวจสอบว่า controller พร้อม
kubectl get pods -n kube-system -l name=sealed-secrets-controller
```

---

## ขั้นตอนที่ 2: ติดตั้ง kubeseal CLI

```bash
# macOS
brew install kubeseal

# Linux (AMD64)
KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags \
  | jq -r '.[0].name' | cut -c 2-)
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# ตรวจสอบ
kubeseal --version
```

---

## ขั้นตอนที่ 3: สร้างและ Encrypt Secret

```bash
# 1. สร้าง Secret ปกติ (dry-run — ไม่ apply ใน cluster)
kubectl create secret generic app-secret \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_PASSWORD=mysecretpassword \
  --from-literal=API_KEY=my-super-secret-api-key \
  --namespace=dev \
  --dry-run=client -o yaml > app-secret.yaml

# 2. ดูไฟล์ (จะเห็น base64 — *** อย่า commit ไฟล์นี้! ***)
cat app-secret.yaml

# 3. Encrypt ด้วย kubeseal
kubeseal \
  --format yaml \
  --namespace dev \
  < app-secret.yaml \
  > sealed-app-secret.yaml

# 4. ดู sealed secret (ปลอดภัย commit ได้!)
cat sealed-app-secret.yaml

# 5. ลบไฟล์ Secret ต้นฉบับ (ห้ามเก็บ!)
rm app-secret.yaml
```

---

## ขั้นตอนที่ 4: Commit และ Push ลง Git

```bash
# Commit sealed secret (ปลอดภัย!)
git add gitops/secrets/sealed-app-secret.yaml
git commit -m "feat: add sealed app secret for dev environment"
git push origin main

# Argo CD จะ detect OutOfSync และ apply SealedSecret อัตโนมัติ
# → Sealed Secrets Controller decrypt → สร้าง Secret ใน namespace dev
```

---

## ขั้นตอนที่ 5: ตรวจสอบ

```bash
# ตรวจสอบว่า Secret ถูกสร้างใน cluster
kubectl get secret app-secret -n dev

# ดูค่า (decode base64)
kubectl get secret app-secret -n dev \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo

# ตรวจสอบ SealedSecret resource
kubectl get sealedsecret app-secret -n dev
```

---

## ข้อควรระวัง

> ⚠️ **Namespace-scoped:** SealedSecret ผูกกับ namespace — ไม่สามารถใช้ข้าม namespace ได้โดยอัตโนมัติ

> ⚠️ **Public key:** ถ้า cluster ถูกลบ → controller key ถูกลบด้วย → decrypt ไม่ได้ ควร backup public/private key ของ controller ไว้

```bash
# Backup controller key (ทำเป็น backup!)
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup.yaml

# เก็บไฟล์นี้ไว้ใน secure location (ไม่ใช่ Git!)
```

---

## ตัวอย่างการใช้ Secret ใน Deployment

```yaml
# deployment.yaml — อ้างอิง secret จาก environment variable
spec:
  containers:
    - name: my-app
      image: ghcr.io/username/my-app:v1.0.0
      env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: app-secret    # ชื่อ Secret ที่ SealedSecret สร้าง
              key: DB_HOST
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: DB_PASSWORD
```

---

---

## GitHub Personal Access Token (PAT) — เชื่อมต่อ Private Repo

ถ้า manifest repo ของคุณเป็น **private repository** Argo CD ต้องการ credentials เพื่อ clone repo ได้

> **วิธีที่แนะนำ:** สร้าง GitHub **Fine-grained PAT** (แทน Classic PAT) เพราะจำกัด scope ได้ละเอียดกว่า

### สร้าง GitHub PAT

ไปที่ GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens**

| Permission | ค่า |
| --- | --- |
| Repository access | เลือก repo ที่ต้องการเท่านั้น |
| Contents | `Read-only` |
| Metadata | `Read-only` (บังคับ) |

---

### วิธีที่ 1: ใส่ Credentials ผ่าน argocd CLI (เร็วสุด)

```bash
# Login Argo CD ก่อน
argocd login localhost:8080 --username admin --password <password> --insecure

# เพิ่ม private repo โดยใช้ PAT
argocd repo add https://github.com/<username>/<repo>.git \
  --username <github-username> \
  --password <your-personal-access-token>

# ตรวจสอบว่าเพิ่มสำเร็จ
argocd repo list
```

ผลลัพธ์ที่ควรเห็น:

```
TYPE  NAME  REPO                                          INSECURE  STATUS      MESSAGE
git         https://github.com/username/repo.git          false     Successful
```

> **หมายเหตุ:** Argo CD เก็บ credentials นี้ใน Secret ชื่อ `repo-<hash>` ใน namespace `argocd` — ไม่ได้เก็บใน Git

---

### วิธีที่ 2: Declarative — Secret ใน argocd namespace

ถ้าต้องการ GitOps แบบ declarative (เก็บได้ใน Git แต่ต้อง encrypt ก่อน):

```yaml
# argocd-repo-secret.yaml
# *** อย่า commit ไฟล์นี้โดยตรง! ใช้ kubeseal ก่อน ***
apiVersion: v1
kind: Secret
metadata:
  name: private-repo-creds
  namespace: argocd
  labels:
    # Label นี้สำคัญมาก — บอก Argo CD ว่า Secret นี้คือ repo credentials
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/<username>/<repo>.git
  username: <github-username>
  # ใส่ PAT ตรงนี้ — ใช้ stringData เพื่อไม่ต้อง base64 มือ
  password: <your-personal-access-token>
```

```bash
# Apply โดยตรง (ไม่ผ่าน Git — เหมาะสำหรับ bootstrap ครั้งแรก)
kubectl apply -f argocd-repo-secret.yaml

# ลบไฟล์ทันทีหลัง apply
rm argocd-repo-secret.yaml

# ตรวจสอบ
argocd repo list
```

---

### วิธีที่ 3: Sealed Secrets สำหรับ Repo Credentials (GitOps-native ✅)

วิธีนี้ให้ commit credentials ใน Git ได้อย่างปลอดภัย — **แนะนำสำหรับ production**:

```bash
# ขั้นตอนที่ 1: สร้าง Secret ปกติ (dry-run)
kubectl create secret generic private-repo-creds \
  --namespace=argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/<username>/<repo>.git \
  --from-literal=username=<github-username> \
  --from-literal=password=<your-personal-access-token> \
  --dry-run=client -o yaml > repo-secret.yaml

# ขั้นตอนที่ 2: เพิ่ม label ที่ Argo CD ต้องการ (แก้ในไฟล์)
# ต้องเพิ่ม label: argocd.argoproj.io/secret-type: repository
# ใช้ kubectl patch หรือแก้ไฟล์ด้วยมือ

# ขั้นตอนที่ 3: Encrypt ด้วย kubeseal
kubeseal \
  --format yaml \
  --namespace argocd \
  < repo-secret.yaml \
  > gitops/secrets/sealed-repo-creds.yaml

# ขั้นตอนที่ 4: ลบไฟล์ต้นฉบับทันที!
rm repo-secret.yaml

# ขั้นตอนที่ 5: Commit sealed secret ลง Git (ปลอดภัย!)
git add gitops/secrets/sealed-repo-creds.yaml
git commit -m "feat: add sealed repo credentials for private repo"
git push origin main
```

ดูตัวอย่างไฟล์ `SealedSecret` สำหรับ repo credentials ได้ที่ `gitops/secrets/sealed-secret-example.yaml`

---

### วิธีที่ 4: Credential Template — ใช้กับหลาย repo ในองค์กรเดียว

ถ้ามีหลาย private repo ใน org เดียวกัน สร้าง **credential template** แทนการสร้าง secret ทีละ repo:

```yaml
# argocd-repo-template.yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-org-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds   # ← ใช้ repo-creds (ไม่ใช่ repository)
stringData:
  type: git
  # URL prefix — Argo CD จะใช้ credentials นี้กับ repo ที่ขึ้นต้นด้วย URL นี้ทั้งหมด
  url: https://github.com/<org-or-username>
  username: <github-username>
  password: <your-personal-access-token>
```

```bash
# Apply credential template
kubectl apply -f argocd-repo-template.yaml
rm argocd-repo-template.yaml

# ตรวจสอบ
argocd repocreds list
```

> **ผลลัพธ์:** ทุก repo ที่ขึ้นต้นด้วย `https://github.com/<org>` จะใช้ PAT นี้อัตโนมัติ — ไม่ต้องเพิ่มทีละ repo

---

### สรุปเปรียบเทียบ 4 วิธี

| วิธี | ง่าย | GitOps | ปลอดภัย | เหมาะกับ |
| --- | :---: | :---: | :---: | --- |
| argocd CLI | ✅ | ❌ | ✅ | dev/workshop |
| kubectl apply Secret ตรง | ✅ | ❌ | ⚠️ | bootstrap ครั้งแรก |
| Sealed Secrets | กลาง | ✅ | ✅✅ | production |
| Credential Template | กลาง | ❌/✅ | ✅ | หลาย repo ใน org เดียว |

---

## อ้างอิง

- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [Sealed Secrets Docs](https://sealed-secrets.netlify.app/)
- [Argo CD Private Repo Docs](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [GitHub Fine-grained PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
- ดูตัวอย่าง SealedSecret ได้ที่ `gitops/secrets/sealed-secret-example.yaml`
