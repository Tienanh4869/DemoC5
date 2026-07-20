# ĐỒ ÁN MÔN ĐIỆN TOÁN ĐÁM MÂY
## Chủ đề: Bảo mật Chuỗi cung ứng Phần mềm Cloud-Native (SLSA, SBOM, Cosign/Sigstore & Zero Trust Policy Enforcement trên Azure AKS)

---

## 1. Giới thiệu & Kiến trúc Đồ án

Đồ án này mô phỏng một **Hệ thống DevSecOps Chuỗi cung ứng Phần mềm Cloud-Native chuẩn mực**, áp dụng mô hình bảo mật **Zero Trust** trên hạ tầng đám mây **Microsoft Azure Kubernetes Service (AKS)**.

### Mục tiêu cốt lõi:
1. **Sử dụng 100% Cloud Builder (`az acr build`):** Đóng gói Container trực tiếp trên máy chủ đám mây Azure, không cần cài đặt hay tiêu tốn tài nguyên Docker Desktop tại máy cá nhân.
2. **Minh bạch hóa thành phần (SBOM):** Sử dụng `Syft` để xuất danh sách chi tiết các gói phụ thuộc (Software Bill of Materials) theo chuẩn **SPDX JSON**.
3. **Ký số mật mã (Cryptographic Signing & Attestation):** Sử dụng `Cosign (Sigstore)` để tạo cặp khóa bất đối xứng (`keys/cosign.key` & `keys/cosign.pub`), tiến hành ký xác thực Container Image và đính kèm SBOM trực tiếp vào **Azure Container Registry (ACR)**.
4. **Enforce Policy trên Kubernetes:** Sử dụng **Kyverno Admission Controller** để áp dụng chính sách **Zero Trust** trên AKS: Tự động CHẶN (`Block/Deny`) bất kỳ Container Image lạ nào không có chữ ký số hợp lệ từ Public Key của tổ chức.

---

## 2. Sơ đồ Kiến trúc & Luồng Bảo mật (Zero Trust Workflow)

```
[Mã nguồn Web Nginx] 
        │
        ▼ (1. Đẩy mã nguồn lên Cloud bằng az acr build)
┌────────────────────────────────────────────────────────┐
│ AZURE CONTAINER REGISTRY (ACR) - CLOUD BUILDER         │
│  ├── Build Docker Image Nginx Non-Root:v1              │
│  ├── Xuất file SBOM (Syft SPDX JSON format)            │
│  └── Ký chữ ký số mật mã Cosign Sign & Attach SBOM     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼ (2. Triển khai Pod lên AKS)
┌────────────────────────────────────────────────────────┐
│ AZURE KUBERNETES SERVICE (AKS CLUSTER)                 │
│  ├── KYVERNO ADMISSION CONTROLLER (Policy Engine)      │
│  │    ├── [x] Pod có Image hợp lệ đã ký -> ALLOW       │
│  │    └── [!] Pod có Image lạ / chưa ký -> DENY        │
│  └── WEB DASHBOARD (Nginx Glassmorphism Dark-Mode)     │
└────────────────────────────────────────────────────────┘
```

---

## 3. Cấu trúc Thư mục Dự án

```text
DemoC5/
├── app/                              # Mã nguồn Web Dashboard bảo mật
│   ├── index.html                    # Giao diện chính (Glassmorphism Dark Mode)
│   ├── style.css                     # Stylesheet với hiệu ứng phát sáng & hoạt ảnh
│   ├── script.js                     # Script xử lý dữ liệu SBOM & giả lập kiểm tra Cosign
│   ├── nginx.conf                    # Cấu hình Nginx bảo mật cho Non-root User
│   └── Dockerfile                    # Dockerfile chuẩn bảo mật Nginx Alpine Non-Root
├── keys/                             # Thư mục chứa cặp khóa mật mã Cosign
│   ├── cosign.key                    # Private Key (dùng để ký Image trên ACR)
│   └── cosign.pub                    # Public Key (cấu hình vào Kyverno Policy trên AKS)
├── policies/                         # Các file Manifest Kubernetes & Policy
│   ├── verify-cosign-policy.yaml     # Kyverno ClusterPolicy yêu cầu xác thực chữ ký
│   ├── deploy-valid.yaml             # Deployment Image đã được ký hợp lệ (ALLOW)
│   └── deploy-invalid.yaml           # Deployment Image giả mạo/chưa ký (DENY)
├── scripts/                          # Bộ script tự động hóa PowerShell
│   ├── 01-setup-azure.ps1            # Cấu hình biến môi trường & Registry
│   ├── 02-build-sign.ps1             # Build trên Cloud ACR, Tạo SBOM & Ký Cosign
│   └── 03-enforce-policy.ps1         # Cài đặt Kyverno, Áp dụng Policy & Test kịch bản
├── README.md                         # Tài liệu tổng quan đồ án (File này)
├── HUONG_DAN_DEMO_AZURE_STUDENT.md   # Hướng dẫn chi tiết cho tài khoản Azure Student
├── HUONG_DAN_TAO_TAY_TREN_AZURE_PORTAL.md # Hướng dẫn ClickOps trên Web Azure Portal
└── WORKFLOW_HUONG_DAN_SU_DUNG.md     # Quy trình từng bước thực hành thuyết trình
```

---

## 4. Hướng dẫn Chạy Nhanh (Quick Start)

### Bước 1: Cài đặt công cụ và Đăng nhập Azure
Mở **PowerShell (Administrator)** để cài đặt 4 công cụ (nếu chưa cài):
```powershell
winget install -e --id Microsoft.AzureCLI
winget install -e --id Kubernetes.kubectl
winget install -e --id Sigstore.Cosign
winget install -e --id Anchore.Syft
```
*(Cài xong đóng PowerShell đó lại, mở lại PowerShell bình thường tại thư mục `DemoC5`).*

Đăng nhập vào Azure (sử dụng chế độ `--use-device-code` nếu gặp lỗi xác thực 2 bước MFA):
```powershell
az login --use-device-code
```

### Bước 2: Chạy bộ 3 Script Tự động hóa
Tại thư mục `C:\Users\tiena\Downloads\DemoC5`, lần lượt chạy 3 lệnh sau:

1. **Thiết lập kết nối với Azure ACR & AKS:**
```powershell
.\scripts\01-setup-azure.ps1
```

2. **Build Image trực tiếp trên Cloud ACR, Xuất SBOM & Ký Cosign:**
```powershell
.\scripts\02-build-sign.ps1
```

3. **Áp dụng Policy Zero Trust lên AKS & Kiểm thử chặn Hacker:**
```powershell
.\scripts\03-enforce-policy.ps1
```

### Bước 3: Xem kết quả Web Dashboard
Mở cổng kết nối từ cụm AKS về máy cá nhân:
```powershell
kubectl port-forward service/cloud-supply-chain-demo 8080:80
```
👉 Truy cập trình duyệt: **[http://localhost:8080](http://localhost:8080)** để xem giao diện Dashboard bảo mật đầy ấn tượng!
