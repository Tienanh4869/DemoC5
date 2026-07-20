# HƯỚNG DẪN CHI TIẾT THỰC HIỆN DEMO TRÊN TÀI KHOẢN AZURE FOR STUDENTS

Tài khoản **Azure for Students** được cấp $100 credit miễn phí nhưng đi kèm với một số giới hạn về **Quota vCPU** (thường từ 4 đến 10 vCPU mỗi Region) và yêu cầu bảo mật xác thực nhiều lớp (MFA).

Tài liệu này hướng dẫn chi tiết cách cấu hình tối ưu nhất để **100% không bị lỗi giới hạn Quota**, không cần cài đặt Docker cá nhân, và chạy mượt mà trên môi trường Windows PowerShell.

---

## 1. Tối Ưu Quota vCPU Khi Tạo Hạ Tầng (ACR & AKS)

### Tên Tài Nguyên Mẫu Trong Đồ ÁN:
- **Resource Group:** `rg-cloud-supply-chain-demo`
- **Azure Container Registry (ACR):** `demobyta` *(hoặc một tên duy nhất do bạn tự đặt, ví dụ `acrdemoc5xxxx`)*
- **Azure Kubernetes Service (AKS):** `aks-supply-chain-demo`

### Cấu Hình Máy Ảo AKS Tối Ưu cho Sinh Viên:
- **Khuyến nghị số lượng Node:** `Node count = 1` *(Chỉ cần 1 node là đủ chạy toàn bộ cụm Kubernetes, tiết kiệm chi phí credit).*
- **Kích thước máy ảo (Node size):**
  - **Khuyến nghị 1 (An toàn nhất, hỗ trợ mọi tính năng):** **`Standard_D2s_v3`** hoặc **`Standard_D2as_v5`** (2 vCPU, 8 GiB RAM). Dòng D-series không bị giới hạn bởi tính năng đặt lịch nâng cấp tự động của Kubernetes.
  - **Khuyến nghị 2 (Tiết kiệm credit tối đa):** **`Standard_B2s`** (2 vCPU, 4 GiB RAM). *Lưu ý: Nếu dùng dòng B-series, bạn bắt buộc phải tắt tính năng `Automatic upgrade` và `Node security channel type` (chọn `Disabled / None`) ở tab Basics trên Portal để tránh lỗi `B-series node sizes cannot be scheduled`.*
- **Availability Zones:** **Bỏ chọn tất cả (để trống)** hoặc chọn `None`. Tránh chọn `Zones 2, 3` vì Azure có thể tự động nhân bản node lên nhiều zone làm vượt Quota IP và vCPU.

---

## 2. Kỹ Thuật Đóng Gói Cloud-Native (Không Cần Docker Desktop)

Một điểm sáng giá của đồ án này là **không cần cài đặt Docker Desktop** trên máy cá nhân:
- Sử dụng lệnh **`az acr build` (Azure Container Registry Cloud Builder)**: Thư mục `app/` chứa mã nguồn HTML/CSS/JS và Nginx cấu hình sẽ được tự động tải lên máy chủ Azure và tiến hành đóng gói siêu tốc trên Cloud.
- Công cụ `cosign` và `syft` sẽ đăng nhập trực tiếp vào OCI Registry trên Cloud thông qua token xác thực (`cosign login`) để xuất SBOM và ký số từ xa.

---

## 3. Cách Xử Lý Các Lỗi Thường Gặp Trên Tài Khoản Sinh Viên

### Lỗi 1: `AADSTS50076: Due to a configuration change... you must use multi-factor authentication`
**Nguyên nhân:** Chính sách của trường hoặc Microsoft Entra ID yêu cầu xác thực 2 bước (MFA) đối với tài khoản sinh viên.
**Cách xử lý:** Luôn sử dụng cờ `--use-device-code` khi đăng nhập:
```powershell
az login --use-device-code
```
*(Sau đó truy cập link `https://microsoft.com/devicelogin`, nhập mã code và xác thực qua ứng dụng Authenticator hoặc SMS trên điện thoại).*

### Lỗi 2: `az : The term 'az' is not recognized...` sau khi cài đặt
**Nguyên nhân:** Windows PowerShell cache lại đường dẫn `PATH` cũ lúc cửa sổ vừa mở.
**Cách xử lý:** Đóng cửa sổ PowerShell hiện tại lại, và **mở lại một cửa sổ PowerShell mới** tại thư mục `DemoC5`.

### Lỗi 3: `Get "http://localhost:8080/openapi/v2...": connectex: No connection could be made`
**Nguyên nhân:** Bạn vừa mở PowerShell mới nhưng chưa tải cấu hình kết nối `kubeconfig` từ cụm AKS trên đám mây về.
**Cách xử lý:** Chạy lệnh lấy thông tin kết nối từ Azure trước khi thao tác với `kubectl`:
```powershell
az aks get-credentials --resource-group rg-cloud-supply-chain-demo --name aks-supply-chain-demo --overwrite-existing
```

---

## 4. Kiểm Thử Kịch Bản Bảo Mật (Demo Scenario)

Trong buổi báo cáo trước thầy cô, bạn sẽ trình diễn 2 kịch bản rõ ràng:

1. **Kịch bản 1 (CHẶN TẤN CÔNG):** Thử triển khai một Container Image lạ từ bên ngoài (`unauthorized-hacker-app:latest`) không có chữ ký của tổ chức.
   👉 **Kết quả:** Admission Controller Kyverno trên AKS chặn đứng lệnh deploy ngay lập tức với thông báo `denied the request... failed to verify signature`.
2. **Kịch bản 2 (CHO PHÉP CHẠY):** Triển khai Container Image hợp lệ (`cloud-supply-chain-demo:v1`) đã được ký bằng Private Key `keys/cosign.key` và đính kèm SBOM hợp lệ.
   👉 **Kết quả:** Pod khởi chạy thành công, cung cấp dịch vụ Web Dashboard cho người dùng.
