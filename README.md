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

## 6. Chi Tiết Cấu Trúc Thư Mục & Phân Tích Ý Nghĩa Từng Thành Phần

Dự án được tổ chức theo mô hình mô-đun hóa cao (`Modular Architecture`), tách biệt rõ ràng giữa tầng **Giao diện/Đóng gói ứng dụng (`app/`)**, tầng **Tự động hóa CI/CD (`.github/workflows/` & `scripts/`)**, tầng **Mật mã & Khóa bảo mật (`keys/`)**, và tầng **Thực thi Zero Trust trên Kubernetes (`policies/`)**.

```text
DemoC5/
├── .github/workflows/
│   └── slsa-cosign-pipeline.yml      # [Trụ cột 1+2+3] Luồng tự động hóa CI/CD GitHub Actions
├── app/                              # [Test Payload] Ứng dụng Web mẫu & cấu hình Docker
│   ├── index.html                    # Giao diện tĩnh tượng trưng (Symbolic Proof UI)
│   ├── style.css                     # Stylesheet Glassmorphism Dark Mode
│   ├── script.js                     # Script kiểm toán trạng thái bảo mật trong Console
│   ├── nginx.conf                    # Cấu hình Nginx Non-Root lắng nghe cổng 8080
│   └── Dockerfile                    # Kịch bản đóng gói Container chuẩn bảo mật Alpine Non-Root
├── keys/                             # [Trụ cột 3] Cặp khóa mật mã Cosign ECDSA
│   ├── cosign.key                    # Private Key (Khóa bí mật - Dùng để ký xác nhận Image)
│   └── cosign.pub                    # Public Key (Khóa công khai - Nạp vào AKS để kiểm tra)
├── policies/                         # [Zero Trust AKS] Khung chính sách Kyverno & Manifests
│   ├── verify-cosign-policy.yaml     # Chính sách Zero Trust chém bay mọi Pod không có chữ ký
│   ├── deploy-valid.yaml             # Manifest triển khai Pod chính chủ (Sử dụng sha256 digest)
│   └── deploy-invalid.yaml           # Manifest kiểm thử tấn công (Pod lạ từ Docker Hub)
├── scripts/                          # Bộ tự động hóa PowerShell cho máy cá nhân/bảo vệ trực tiếp
│   ├── 01-setup-azure.ps1            # Khởi tạo Resource Group, ACR Registry & Cụm AKS
│   ├── 02-build-sign.ps1             # Build Cloud, Quét SBOM Syft & Ký số Cosign
│   └── 03-enforce-policy.ps1         # Cài đặt Kyverno, Áp dụng chính sách & Chạy 2 Test Case
├── README.md                         # Tài liệu tổng quan kiến trúc đồ án (File này)
├── WORKFLOW_HUONG_DAN_SU_DUNG.md     # Kịch bản thuyết trình chi tiết & phối hợp 3 màn hình
└── KICH_BAN_THUYET_TRINH_DEMO.txt    # Tệp Notepad thuần túy phục vụ copy-paste & lời thoại nhanh
```

---

### 🔍 Phân Tích Kỹ Thuật Chuyên Sâu Từng Thư Mục & File Thành Phần:

#### 1. Thư mục `.github/workflows/` — Tự động hóa CI/CD & SLSA Provenance
* **`slsa-cosign-pipeline.yml`**: Là trái tim của tự động hóa chuỗi cung ứng trên đám mây. File YAML này định nghĩa quy trình **CI/CD Pipeline** chạy trên máy chủ GitHub Actions mỗi khi có thay đổi mã nguồn.
  * **Trách nhiệm:** Đăng nhập an toàn vào Azure Container Registry (`demobyta.azurecr.io`) thông qua Secrets; đóng gói Docker Image; gọi công cụ **Syft** bóc tách xuất file `cloud-demo-sbom.json` (`SPDX-JSON`); và gọi công cụ **Cosign** sử dụng `COSIGN_PRIVATE_KEY` để ký số, đính kèm (`attest`) SBOM trực tiếp vào Registry.
  * **Ý nghĩa thực tiễn:** Khẳng định việc bảo mật chuỗi cung ứng được tự động hóa 100%, không phụ thuộc thao tác thủ công, đạt chuẩn **SLSA Build Level 3**.

#### 2. Thư mục `app/` — Đối tượng đích mẫu (Demo Payload) & Bảo mật Container lõi
* **`Dockerfile`**: Áp dụng triết lý bảo mật từ gốc (`Secure by Design`). Sử dụng ảnh gốc siêu nhẹ `nginx:1.26-alpine` để giảm thiểu bề mặt tấn công (chỉ chứa các thư viện tối thiểu). Đặc biệt, cấu hình chạy dưới quyền người dùng **Non-Root (`USER nginx`)** thay vì `root`, ngăn chặn triệt để lỗ hổng leo thang đặc quyền nếu Container bị xâm nhập.
* **`nginx.conf`**: Cấu hình máy chủ Web Nginx lắng nghe ở cổng **`8080`** (vì tài khoản Non-Root không có quyền mở các cổng hệ thống dưới 1024 như cổng 80). Tích hợp sẵn endpoint `/healthz` phục vụ cơ chế tự chẩn đoán liveness/readiness probe của Kubernetes.
* **`index.html` / `style.css` / `script.js`**: Giao diện trực quan tượng trưng (Symbolic Proof UI) được mount vào Pod thông qua Kubernetes ConfigMap. Mục đích của trang Web không phải là làm giao diện phức tạp, mà để đóng vai trò là **Bằng chứng sống (Proof of Service Delivery)** minh chứng rằng: Pod sau khi vượt qua quy trình kiểm duyệt Zero Trust khắt khe của Kyverno vẫn vận hành mượt mà, tốc độ cao và phản hồi chính xác nội dung nghiệp vụ.

#### 3. Thư mục `keys/` — Tầng Mật mã Bản quyền (Sigstore Cosign Keypair)
* **`cosign.key` (Private Key - Khóa bí mật)**: Được mã hóa bằng mật khẩu (`AzureStudentDemoPassword123!`), giữ vai trò như "Con dấu bản quyền tối cao" của tổ chức phát triển phần mềm. Chỉ có hệ thống CI/CD hợp lệ mới được quyền truy cập khóa này để ký (`sign`) lên các Container Image sau khi build thành công.
* **`cosign.pub` (Public Key - Khóa công khai)**: Khóa này được nạp thẳng vào bộ nhớ của máy chủ Azure Kubernetes Service (AKS) và đưa cho "Người gác cổng" Kyverno cầm. Khi bất kỳ ai ra lệnh chạy một Pod, Kyverno sẽ lấy khóa công khai này đối chiếu với chữ ký trên Azure Registry để xác minh xem Pod đó có đúng do chủ nhân của `cosign.key` tạo ra hay không.

#### 4. Thư mục `policies/` — Tầng Thực thi Pháo đài Zero Trust trên Kubernetes
* **`verify-cosign-policy.yaml`**: Manifest quan trọng nhất của mô hình Zero Trust Admission Control. Sử dụng Custom Resource Definition (`ClusterPolicy`) của **Kyverno**.
  * **Cơ chế hoạt động:** Chặn ở cổng vào (`Admission Webhook`) trước khi Pod kịp sinh ra. Chính sách quy định tất cả Pod (`*`) triển khai vào cụm AKS bắt buộc phải có chữ ký hợp lệ (`verifyImages`) khớp với `cosign.pub`. Đồng thời thiết lập `mutateDigest: false` để giữ nguyên tính toàn vẹn và `validationFailureAction: Enforce` để tiêu diệt ngay lập tức (`DENY`) nếu phát hiện vi phạm.
* **`deploy-valid.yaml`**: Manifest triển khai Pod ứng dụng hợp lệ (`cloud-supply-chain-demo`). Đặc biệt, thay vì dùng tag dễ bị làm giả như `:v1` hay `:latest`, file này sử dụng **Chính xác mã băm bất biến (Immutable SHA256 Digest)**: `@sha256:a456...`. Đây là tiêu chuẩn vàng của SLSA & Sigstore, giúp đảm bảo 1000% Pod chạy đúng phiên bản mã nguồn đã kiểm thử.
* **`deploy-invalid.yaml`**: Manifest kịch bản kiểm thử tấn công (Test Payload). Cố tình ra lệnh cho AKS chạy một Image chuẩn từ mạng nhưng không có chữ ký của nhóm (`unauthorized-hacker-app:latest` hoặc `nginx:latest`) để chứng minh màng lọc Kyverno chém bay đầu virus trong 0.1 giây.

#### 5. Thư mục `scripts/` — Bộ Công cụ Kịch bản Tự động hóa (PowerShell Automation)
* **`01-setup-azure.ps1`**: Kịch bản chuẩn bị hạ tầng Cloud. Tự động kết nối Azure CLI, khởi tạo Nhóm tài nguyên (`rg-cloud-supply-chain-demo`), Registry (`demobyta`) và Cụm Kubernetes AKS (`aks-supply-chain-demo`). Sau đó tự động kết nối quyền truy cập (`az aks update --attach-acr`) để AKS có quyền kéo Image từ ACR.
* **`02-build-sign.ps1`**: Kịch bản đóng vai trò như một môi trường CI/CD cục bộ trên máy cá nhân (giúp bạn chủ động báo cáo trực tiếp tại lớp trong 10-15 phút mà không sợ mạng chậm hay chờ đợi hàng đợi GitHub). Thực thi lệnh `az acr build` trên Cloud, tạo cặp khóa Cosign, xuất file SBOM chuẩn `SPDX-JSON` bằng Syft, và thực hiện ký số Cosign lên Registry.
* **`03-enforce-policy.ps1`**: Kịch bản thực chiến Zero Trust trên Kubernetes. Tự động cài đặt Kyverno vào AKS thông qua Helm Chart, nạp chính sách `verify-cosign-policy.yaml`, nạp ConfigMap giao diện Web, sau đó lần lượt chạy tự động **2 Test Case thực chiến**:
  * *Test Case 1 (Chặn Hacker):* Thử deploy `deploy-invalid.yaml` $\rightarrow$ Ghi nhận lỗi chém bay đầu (`DENY`).
  * *Test Case 2 (Cho phép Hợp lệ):* Deploy `deploy-valid.yaml` với mã băm sha256 $\rightarrow$ Ghi nhận Pod khởi chạy thành công (`ALLOW`).

#### 6. Các Tài liệu Hướng dẫn Khung (Root Documentation)
* **`README.md`**: Tài liệu kỹ thuật tổng quan toàn diện, tổng hợp lý thuyết, sơ đồ kiến trúc, bảng đối chiếu 4 trụ cột và cẩm nang thao tác nhanh.
* **`WORKFLOW_HUONG_DAN_SU_DUNG.md`**: Kịch bản đạo diễn chi tiết cho buổi bảo vệ đồ án. Chia làm 5 phần đắt giá kèm lời thoại cụ thể từng câu, hướng dẫn phối hợp nhịp nhàng giữa **3 Màn hình đỉnh cao** (GitHub Actions $\leftrightarrow$ PowerShell Terminal $\leftrightarrow$ Web Dashboard).
* **`KICH_BAN_THUYET_TRINH_DEMO.txt`**: Phiên bản văn bản thuần (`ASCII/UTF-8 BOM`) tối ưu hóa để mở bằng Notepad trên Windows trong phòng bảo vệ. Giúp bạn copy-paste lệnh nhanh chóng và xem lời thoại không bị nhiễu định dạng Markdown.
