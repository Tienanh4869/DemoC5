# QUY TRÌNH THỰC HÀNH & KỊCH BẢN THUYẾT TRÌNH BÁO CÁO ĐỒ ÁN
## Chủ đề: Bảo mật Chuỗi cung ứng Phần mềm Cloud-Native (SLSA, SBOM Syft, Cosign Sigstore & Zero Trust Kyverno trên Azure AKS)

Tài liệu này là **cẩm nang lời thoại và quy trình chuẩn hóa từng bước** giúp bạn tự tin thuyết trình trước hội đồng, kết hợp chứng minh trực quan trên cả **Azure Portal**, **Terminal PowerShell** và **Web Dashboard**.

---

## 1. CÔNG TÁC CHUẨN BỊ (Trước giờ báo cáo 15 phút)

1. Bật máy tính, mở **PowerShell** tại thư mục `DemoC5`.
2. Kiểm tra/kết nối lại tài khoản Azure và Kubernetes:
```powershell
az login --use-device-code
az aks get-credentials --resource-group rg-cloud-supply-chain-demo --name aks-supply-chain-demo --overwrite-existing
kubectl get pods -l app=secure-demo
```
*(Đảm bảo Pod `cloud-supply-chain-demo-...` đang hiển thị trạng thái `Running 1/1`).*

3. Mở sẵn các tab trên trình duyệt Chrome/Edge:
   - **Tab 1:** GitHub Repository của bạn (mở tab `Actions` để sẵn sàng khoe luồng CI/CD tự động).
   - **Tab 2:** Azure Portal (`https://portal.azure.com`), vào Resource Group `rg-cloud-supply-chain-demo`.
   - **Tab 3:** Trang Web Dashboard (`http://localhost:8080` sau khi chạy lệnh port-forward).

---

## 2. KỊCH BẢN THUYẾT TRÌNH & CHỈ TAY TẬN MẮT TRÊN 3 MÀN HÌNH

### PHẦN 1: Giới thiệu Kiến trúc & 3 Trụ Cột Bảo Mật (2 phút)
🗣️ **Lời thoại:**
> *"Kính chào thầy cô trong hội đồng. Hôm nay em xin trình bày đồ án: **Xây dựng và Triển khai Bảo mật Chuỗi cung ứng Phần mềm Cloud-Native** theo khung tiêu chuẩn quốc tế SLSA, sử dụng công cụ SBOM Syft, chữ ký số Cosign/Sigstore và mô hình Zero Trust trên nền tảng đám mây Microsoft Azure.
> 
> Hệ thống của em giải quyết bài toán chống lại các cuộc tấn công chuỗi cung ứng nguy hiểm (như SolarWinds, Log4j) bằng cách thiết lập 3 trụ cột khóa chặt vào nhau:*
> 1. *Khung **SLSA & CI/CD tự động** bảo vệ môi trường build và gán nhãn xuất xứ Provenance.*
> 2. *Bảng kê khai **SBOM (Syft)** minh bạch hóa 100% các gói thư viện, loại bỏ tình trạng hộp đen.*
> 3. *Chữ ký số mật mã **Cosign (Sigstore)** đóng dấu bản quyền, niêm phong chống sửa đổi.*
> *Và cuối cùng, Người gác cổng **Kyverno Admission Controller** trên máy chủ Azure Kubernetes Service (AKS) thực thi chính sách Zero Trust: chỉ chấp nhận cho chạy các Container có đủ chữ ký và SBOM sạch."*

---

### PHẦN 2: Chứng minh Trụ cột 1 & 2 - CI/CD Tự động hóa & SBOM trên GitHub Actions (2 phút)
👉 **Thao tác trên màn hình:** Mở trình duyệt, chuyển sang tab **GitHub Actions (`slsa-cosign-pipeline.yml`)**.

🗣️ **Lời thoại:**
> *"Thưa thầy cô, đúng như triết lý bảo mật chuỗi cung ứng: **'Mọi quy trình bảo mật phải được tích hợp tự động, không can thiệp thủ công'**.
> 
> Khi lập trình viên đẩy mã nguồn lên nhánh `main` của GitHub, hệ thống CI/CD đã tự động thực thi trọn vẹn 6 bước trên đám mây (như thầy cô thấy các tích xanh trên màn hình):*
> - *Tự động đóng gói (`Build and Push`) ứng dụng lên Azure Container Registry.*
> - *Công cụ **Syft** tự động bóc tách lớp Container Nginx/Alpine để xuất ra bảng SBOM `cloud-demo-sbom.json` chuẩn `SPDX-JSON`.*
> - *Công cụ **Cosign** tự động lấy Private Key ECDSA từ GitHub Secrets để ký chữ ký số mật mã và đính kèm SBOM trực tiếp lên Cloud."*

👉 **Thao tác phụ chứng minh SBOM:** Mở file `cloud-demo-sbom.json` trong VS Code cho thầy cô thấy cấu trúc chuẩn `SPDX-2.3` và danh sách chi tiết các thư viện Nginx/OpenSSL.

---

### PHẦN 3: Chứng minh Trụ cột 3 & Hạ tầng trên Azure Portal (`portal.azure.com`) (2 phút)
👉 **Thao tác trên màn hình:** Chuyển sang tab **Azure Portal (`portal.azure.com`)**, mở Registry **`demobyta`** $\rightarrow$ **Repositories** $\rightarrow$ `cloud-supply-chain-demo` $\rightarrow$ Click vào tag `v1`.

🗣️ **Lời thoại:**
> *"Dưới đây là minh chứng thực tế trên giao diện quản trị đám mây chính chủ của Microsoft Azure:
> Thầy cô có thể thấy bên cạnh Container Image chính (`v1`), hệ thống đã lưu trữ bảo mật các tạo tác đi kèm mang mã băm `sha256-...`. Đây chính là **Chữ ký số Cosign (`.sig`)** và **Bảng thành phần SBOM (`.sbom`)** đã được niêm phong vĩnh viễn trên đám mây Azure!"*

---

### PHẦN 4: Màn Trình Diễn Đỉnh Cao - Cảnh "Chém Bay Đầu Hacker Zero Trust" trên AKS (3 phút)
👉 **Thao tác trên màn hình:** Chuyển sang tab **Azure Portal**, mở cụm Kubernetes **`aks-supply-chain-demo`** $\rightarrow$ **Workloads** $\rightarrow$ Chỉ cho thầy cô thấy Pod ứng dụng đang `Running` và Pod gác cổng `kyverno-admission-controller` đang hoạt động.

🗣️ **Lời thoại:**
> *"Và đây là minh chứng thực chiến quan trọng và đắt giá nhất của đồ án: Khả năng tự động phòng thủ Zero Trust trên máy chủ Kubernetes AKS."*

👉 **Thao tác biểu diễn trực tiếp trên Terminal PowerShell:**
Gõ lệnh chạy thử một Container Image từ mạng không có chữ ký số của tổ chức:
```powershell
kubectl run hacker-pod --image=nginx:latest
```
👉 **Màn hình lập tức báo lỗi đỏ:** `Error from server: admission webhook "mutate.kyverno.svc-fail" denied the request... no matching signatures`.

🗣️ **Lời thoại chốt hạ kịch tính:**
> *"Thầy cô thấy không ạ? Mặc dù `nginx:latest` là image chuẩn từ Docker Hub, nhưng vì **không có chữ ký mật mã hợp lệ từ Public Key của nhóm em**, Người gác cổng Kyverno đã lập tức **CHẶN ĐỨNG (`DENY`)** trong 0.1 giây, không cho Pod độc hại có cơ hội sinh ra trên máy chủ!
> 
> Ngược lại, Pod ứng dụng `cloud-supply-chain-demo` chính chủ của nhóm đã đi qua quy trình kiểm duyệt, xác thực chữ ký khớp 100% nên được phép chạy (`ALLOW`) và cung cấp dịch vụ cho người dùng."*

---

### PHẦN 5: Trình diễn Web Dashboard & Kết luận (1 phút)
👉 **Thao tác trên màn hình:** Chuyển sang tab trình duyệt đang mở **`http://localhost:8080`**. Bấm nút **`⚡ Kiểm Trực Tiếp Chữ Ký (Verify Live)`**.

🗣️ **Lời thoại kết luận:**
> *"Và đây là giao diện Web Dashboard mô phỏng trực quan kết quả của hệ thống: hiển thị đầy đủ chứng nhận **VERIFIED BY AKS POLICY ENGINE**, chuẩn xác thực **SLSA Level 3**, danh sách **SBOM** và chữ ký **Cosign Verified**.
> 
> Đồ án đã biến bảo mật chuỗi cung ứng từ một khái niệm trừu tượng thành một hệ thống pháo đài tự động, thực chiến và kiên cố trên đám mây Azure. Em xin chân thành cảm ơn thầy cô đã lắng nghe và em rất mong nhận được ý kiến đóng góp ạ!"*
