# ĐỒ ÁN MÔN ĐIỆN TOÁN ĐÁM MÂY
## Chủ đề: Xây dựng và triển khai Bảo mật Chuỗi cung ứng Phần mềm Cloud-Native (SLSA, SBOM, Cosign/Sigstore & Zero Trust Policy Enforcement trên Azure AKS)

---

## 1. Giới thiệu & Kiến trúc Đồ án

Đồ án này nghiên cứu và hiện thực hóa một **Hệ sinh thái DevSecOps Chuỗi cung ứng Phần mềm Cloud-Native chuẩn mực**, áp dụng mô hình bảo mật **Zero Trust (Không tin cậy bất kỳ ai)** trên hạ tầng đám mây **Microsoft Azure Kubernetes Service (AKS)** và **Azure Container Registry (ACR)**.

### Mục tiêu và 4 Trụ cột Thực chiến:
1. **Khung tiêu chuẩn SLSA & TỰ ĐỘNG HÓA CI/CD:** Xây dựng luồng tự động hóa trên **GitHub Actions (`slsa-cosign-pipeline.yml`)** và kỹ thuật **Azure Cloud Builder (`az acr import/build`)**, đảm bảo môi trường Build an toàn, chuẩn hóa xuất xứ `Provenance Level 3`.
2. **Minh bạch hóa thành phần (SBOM - Syft):** Loại bỏ rủi ro "hộp đen" trong Container bằng cách tự động quét, bóc tách và tạo danh sách nguyên vật liệu phần mềm (Software Bill of Materials) theo chuẩn quốc tế **SPDX JSON**, đính kèm (`attestation`) trực tiếp lên đám mây Azure.
3. **Ký số mật mã chống giả mạo (Sigstore Cosign):** Sử dụng cặp khóa mật mã bất đối xứng ECDSA (`keys/cosign.key` & `keys/cosign.pub`) để niêm phong bản quyền Container Image. Bất kỳ sự thay đổi trái phép dù chỉ 1 bit sau khi build đều bị phát hiện.
4. **Pháo đài Zero Trust trên Kubernetes (Kyverno Admission Controller):** Thực thi chính sách "Người gác cổng" trên cụm AKS: Tự động **CHẶN ĐỨNG (`Block/Deny`)** mọi Container lạ/chưa ký số, và **CHO PHÉP (`Allow`)** Container chính chủ đã được kiểm duyệt.

---

## 2. Sơ đồ Kiến trúc & Luồng Bảo mật (Zero Trust Workflow)

```
[Mã nguồn Web Nginx / GitHub Push Commit] 
                   │
                   ▼ (1. CI/CD Pipeline trên GitHub Actions hoặc PowerShell Script)
┌────────────────────────────────────────────────────────────────────────┐
│ AZURE CONTAINER REGISTRY (ACR: demobyta.azurecr.io)                    │
│  ├── Build/Import Docker Image Nginx Non-Root:v1                       │
│  ├── Xuất file SBOM (Syft SPDX JSON format - cloud-demo-sbom.json)     │
│  └── Ký chữ ký số mật mã Cosign Sign & Attach Attestation (.sig/.sbom) │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼ (2. Triển khai Pod lên AKS)
┌────────────────────────────────────────────────────────────────────────┐
│ AZURE KUBERNETES SERVICE (AKS CLUSTER: aks-supply-chain-demo)          │
│  ├── KYVERNO ADMISSION CONTROLLER (Zero Trust Policy Engine)           │
│  │    ├── [!] Thử chạy Image lạ (nginx:latest) ──► DENY (Chém bay đầu) │
│  │    └── [x] Pod Image chính chủ đã ký Cosign  ──► ALLOW (Cho chạy)   │
│  └── WEB DASHBOARD (Nginx Glassmorphism Dark-Mode tại Port 80)         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Bảng Đối Chiếu: Nghiên Cứu Lý Thuyết vs Minh Chứng Thực Hành

| Nội Dung Nghiên Cứu | Lời Giảng Lý Thuyết | Minh Chứng Thực Tế Trong Đồ Án (Mắt Thấy Tai Nghe) |
| :--- | :--- | :--- |
| **Trụ cột 1:<br>SLSA & CI/CD** | *"SLSA bảo vệ nhà máy..."*<br>Đảm bảo quy trình build tự động, có tem nhãn xuất xứ rõ ràng (`Provenance`). | 👉 **Minh chứng trên GitHub Actions (`slsa-cosign-pipeline.yml`):**<br>- Mở tab `Actions` trên GitHub $\rightarrow$ Thấy rõ 6 bước tự động (Build, Syft, Cosign, Push) chạy thành công màu xanh lá mà không cần can thiệp thủ công tay. |
| **Trụ cột 2:<br>SBOM (Syft)** | *"SBOM liệt kê nguyên liệu..."*<br>Minh bạch hóa thành phần phần mềm chuẩn **SPDX/CycloneDX**. | 👉 **Minh chứng file JSON & Cloud Registry:**<br>- File `cloud-demo-sbom.json` hiển thị chuẩn `SPDX-2.3` kèm hàng chục thư viện bên trong Nginx.<br>- Lệnh `cosign tree demobyta.azurecr.io/cloud-supply-chain-demo:v1` hiển thị cây đính kèm `.sbom` trên Azure. |
| **Trụ cột 3:<br>Sigstore Cosign** | *"Sigstore niêm phong thành phẩm..."*<br>Ký số mật mã chống làm giả, bảo vệ tính toàn vẹn (`Integrity`). | 👉 **Minh chứng khóa ECDSA & Lệnh Verify:**<br>- Thư mục `keys/` chứa cặp khóa `cosign.key` / `cosign.pub`.<br>- Lệnh `cosign verify --key keys/cosign.pub ...` xác thực chữ ký thành công `SUCCESS`. |
| **Zero Trust<br>Admission Control** | *"Chỉ chấp nhận các container image có chữ ký xác thực hợp lệ và SBOM sạch."* | 👉 **Minh chứng trên Terminal PowerShell & Azure AKS:**<br>- **Chặn Hacker:** Gõ `kubectl run hacker-pod --image=nginx:latest` $\rightarrow$ Bị chặn đứng lập tức (`denied: no matching signatures`).<br>- **Cho phép Hợp lệ:** Pod chính chủ khởi chạy thành công (`Running 1/1`). |

---

## 4. Hướng Dẫn Chứng Minh Trên Web Azure Portal (`portal.azure.com`)

Thầy cô hội đồng rất thích nhìn tận mắt tài nguyên đang hoạt động trên giao diện Web chính chủ của Microsoft Azure. Bạn có thể chứng minh 3 điểm sau:

1. **Chứng minh Hạ tầng Resource Group:**
   - Mở `https://portal.azure.com` $\rightarrow$ **Resource groups** $\rightarrow$ `rg-cloud-supply-chain-demo`.
   - Hiển thị song hành 2 dịch vụ: Registry `demobyta` và cụm Kubernetes `aks-supply-chain-demo`.
2. **Chứng minh Chữ ký Cosign & SBOM lưu trên Cloud Registry:**
   - Vào `demobyta` $\rightarrow$ **Repositories** $\rightarrow$ `cloud-supply-chain-demo` $\rightarrow$ Click vào tag `v1`.
   - Nhìn bên dưới tag `v1` sẽ thấy các tạo tác đi kèm mang mã băm `sha256-...` (chính là chữ ký `.sig` và bảng `.sbom` được niêm phong trên đám mây Azure).
3. **Chứng minh "Người gác cổng" Kyverno & Pod ứng dụng trên AKS:**
   - Vào `aks-supply-chain-demo` $\rightarrow$ **Workloads** (dưới mục *Kubernetes resources*).
   - Ở tab *Deployments* và *Pods* sẽ thấy `cloud-supply-chain-demo` đang ở trạng thái xanh lá (`Running 1/1`). Chuyển namespace sang `All namespaces` sẽ thấy các Pod của `kyverno-admission-controller` đang chạy 24/7 để bảo vệ cụm.

---

## 5. Cẩm Nang Chạy Demo Cho Ngày Bảo Vệ (Quick Start)

**LƯU Ý QUAN TRỌNG:** Toàn bộ cụm AKS, Registry ACR và Chính sách Kyverno **ĐÃ ĐƯỢC LƯU TRỮ VĨNH VIỄN TRÊN CLOUD AZURE**. Ngày mai khi bật máy báo cáo, bạn **KHÔNG CẦN CÀI ĐẶT LẠI TỪ ĐẦU**, chỉ cần 3 thao tác siêu nhanh:

### Bước 1: Kết nối lại phiên Azure CLI & AKS
Mở PowerShell tại thư mục `DemoC5` và gõ:
```powershell
az login --use-device-code
az aks get-credentials --resource-group rg-cloud-supply-chain-demo --name aks-supply-chain-demo --overwrite-existing
```

### Bước 2: Bật cổng Web Dashboard
```powershell
kubectl port-forward service/cloud-supply-chain-demo 8080:80
```
👉 Mở trình duyệt vào **[http://localhost:8080](http://localhost:8080)** để hiển thị Web Dashboard bảo mật lung linh phục vụ người dùng.

### Bước 3: Biểu diễn Live cảnh "Chém bay đầu Hacker Zero Trust"
Mở **thêm 1 tab PowerShell thứ 2**, gõ lệnh chạy thử Container lạ từ mạng:
```powershell
kubectl run hacker-pod --image=nginx:latest
```
👉 Thầy cô sẽ chứng kiến lỗi đỏ hiện lên tức thì: `Error from server: admission webhook "mutate.kyverno.svc-fail" denied the request... no matching signatures`.

---

## 6. Cấu Trúc Thư Mục Dự Án

```text
DemoC5/
├── .github/workflows/
│   └── slsa-cosign-pipeline.yml      # Luồng tự động hóa CI/CD trên GitHub Actions
├── app/                              # Mã nguồn Web Dashboard bảo mật Nginx
│   ├── index.html                    # Giao diện chính (Glassmorphism Dark Mode)
│   ├── style.css                     # Stylesheet với hiệu ứng phát sáng
│   ├── script.js                     # Script mô phỏng luồng kiểm tra chữ ký Cosign
│   └── Dockerfile                    # Dockerfile chuẩn bảo mật Nginx Alpine Non-Root
├── keys/                             # Cặp khóa mật mã Cosign ECDSA
│   ├── cosign.key                    # Private Key (Khóa bí mật dùng ký Image)
│   └── cosign.pub                    # Public Key (Khóa công khai cấu hình vào AKS)
├── policies/                         # Các Manifest Kubernetes & Policy
│   ├── verify-cosign-policy.yaml     # Kyverno ClusterPolicy phạm vi * (Enforce)
│   ├── deploy-valid.yaml             # Deployment Image đã được ký hợp lệ (ALLOW)
│   └── deploy-invalid.yaml           # Deployment Image giả mạo/chưa ký (DENY)
├── scripts/                          # Bộ script tự động hóa PowerShell
│   ├── 01-setup-azure.ps1            # Cấu hình biến môi trường & Registry
│   ├── 02-build-sign.ps1             # Build trên Cloud ACR, Xuất SBOM & Ký Cosign
│   └── 03-enforce-policy.ps1         # Nạp Kyverno, Áp dụng Policy & Test kịch bản
├── README.md                         # Tài liệu tổng quan đồ án (File này)
└── WORKFLOW_HUONG_DAN_SU_DUNG.md     # Kịch bản thuyết trình & chỉ tay tận mắt 3 màn hình
```
