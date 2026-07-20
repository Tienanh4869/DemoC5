# QUY TRÌNH THỰC HÀNH & KỊCH BẢN THUYẾT TRÌNH BÁO CÁO

Tài liệu này là **lời thoại và quy trình từng bước chuẩn hóa** giúp bạn tự tin thuyết trình trước thầy cô và chạy demo thực tế không gặp lỗi.

---

## 1. CÔNG TÁC CHUẨN BỊ (Trước giờ báo cáo 15 phút)

1. Mở cửa sổ **PowerShell** mới tại thư mục `DemoC5`.
2. Kiểm tra trạng thái đăng nhập Azure CLI và kết nối Kubernetes:
```powershell
az login --use-device-code
az aks get-credentials --resource-group rg-cloud-supply-chain-demo --name aks-supply-chain-demo --overwrite-existing
kubectl get nodes
```
*(Đảm bảo hiển thị node với status `Ready`).*

3. Kiểm tra file `scripts\.acr_env` đảm bảo chứa đúng tên Registry của bạn (ví dụ `demobyta.azurecr.io`).

---

## 2. KỊCH BẢN THUYẾT TRÌNH TỪNG BƯỚC

### PHẦN 1: Giới thiệu Kiến trúc & Hạ tầng Cloud-Native
🗣️ **Lời thoại:**
> *"Kính chào thầy cô. Hôm nay em xin trình bày đồ án: **Bảo mật Chuỗi cung ứng Phần mềm Cloud-Native (Supply Chain Security)** sử dụng SLSA, SBOM, Cosign/Sigstore và Zero Trust Policy Enforcement trên hạ tầng Microsoft Azure.*
> *Hệ thống của em được triển khai 100% trên đám mây Azure bao gồm kho lưu trữ **Azure Container Registry (ACR)** và cụm máy chủ **Azure Kubernetes Service (AKS)**."*

---

### PHẦN 2: Đóng gói trên Cloud (`az acr build`), Tạo SBOM & Ký số Cosign
🗣️ **Lời thoại:**
> *"Để đảm bảo tính linh hoạt và tiết kiệm tài nguyên máy cá nhân, em không dùng Docker cục bộ mà áp dụng kỹ thuật **Azure Cloud Builder (`az acr build`)**. Toàn bộ mã nguồn Web Dashboard Nginx được tải trực tiếp lên đám mây Azure để đóng gói."*

👉 **Thao tác trên máy:** Chạy script bước 2:
```powershell
.\scripts\02-build-sign.ps1
```
🗣️ **Giải thích trong lúc chờ script chạy:**
> *"Như thầy cô thấy trên màn hình:
> 1. Azure Cloud Builder đang tiến hành build Image Nginx Non-Root trực tiếp trên máy chủ đám mây.
> 2. Sau khi build xong, công cụ **Syft** lập tức quét toàn bộ các gói thư viện bên trong Container để xuất ra bảng kê khai thành phần phần mềm (**SBOM - Software Bill of Materials**) dưới dạng chuẩn `SPDX JSON`.
> 3. Cuối cùng, công cụ mật mã **Cosign** sử dụng cặp khóa bất đối xứng (`keys/cosign.key`) để ký chữ ký số mật mã lên Image, đồng thời đính kèm file SBOM vào Registry `demobyta.azurecr.io`."*

---

### PHẦN 3: Zero Trust Policy Enforcement trên AKS & Demo Kịch bản Bảo mật
🗣️ **Lời thoại:**
> *"Để ngăn chặn mọi nguy cơ lây nhiễm mã độc hoặc image giả mạo bị thâm nhập vào hệ thống production, em cài đặt bộ kiểm soát chính sách **Kyverno Admission Controller** hoạt động theo mô hình **Zero Trust** trên cụm Kubernetes."*

👉 **Thao tác trên máy:** Chạy script bước 3:
```powershell
.\scripts\03-enforce-policy.ps1
```

🗣️ **Giải thích từng kịch bản khi script in ra kết quả:**
> 1. **Kịch bản 1 (CHẶN HACKER):** *"Khi hệ thống nhận lệnh triển khai một Container Image lạ từ bên ngoài (`unauthorized-hacker-app:latest`) không có chữ ký của tổ chức, Kyverno Admission Controller đã kiểm tra Public Key và **CHẶN ĐỨNG ngay từ vòng gửi xe** với thông báo `denied the request... failed to verify signature`."*
> 2. **Kịch bản 2 (CHO PHÉP CHẠY):** *"Ngược lại, khi triển khai Image chính chủ đã được ký xác thực bởi Cosign ở Bước 2, Kyverno xác thực chữ ký hợp lệ và cho phép Pod khởi chạy thành công vào cụm AKS!"*

---

### PHẦN 4: Trình diễn Web Dashboard Bảo mật
👉 **Thao tác trên máy:** Mở cổng kết nối để hiển thị giao diện Web:
```powershell
kubectl port-forward service/cloud-supply-chain-demo 8080:80
```
👉 **Mở trình duyệt:** Vào **`http://localhost:8080`**

🗣️ **Lời thoại kết luận:**
> *"Đây là giao diện Web Dashboard mô phỏng trực quan kết quả đồ án: hiển thị danh sách chi tiết các gói thư viện SBOM, trạng thái xác thực chữ ký số Cosign Cryptographic Signature, và bằng chứng SLSA Provenance Level 3 đạt chuẩn bảo mật Cloud-Native.
> Em xin kết thúc bài báo cáo và kính mời thầy cô đặt câu hỏi ạ!"*
