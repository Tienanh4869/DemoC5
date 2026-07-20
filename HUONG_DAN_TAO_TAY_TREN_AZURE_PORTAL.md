# HƯỚNG DẪN TẠO TAY TÀI NGUYÊN TRÊN WEB AZURE PORTAL (MANUAL CLICKOPS)

Tài liệu này hướng dẫn chi tiết từng bước bấm chuột tạo tài nguyên trực tiếp trên giao diện Web Azure Portal dành cho trường hợp thầy cô yêu cầu thao tác trực quan trên trình duyệt.

---

## BƯỚC 1: ĐĂNG NHẬP VÀO AZURE PORTAL
1. Mở trình duyệt và truy cập: [https://portal.azure.com](https://portal.azure.com)
2. Đăng nhập bằng tài khoản **Azure for Students** của bạn.

---

## BƯỚC 2: TẠO RESOURCE GROUP (NHÓM TÀI NGUYÊN)
1. Tại trang chủ Azure Portal, gõ vào thanh tìm kiếm phía trên: **`Resource groups`** và nhấp chọn.
2. Nhấp vào nút **`+ Create`** (Tạo mới).
3. Điền thông tin:
   - **Subscription:** `Azure for Students`
   - **Resource group:** Gõ tên `rg-cloud-supply-chain-demo`
   - **Region:** Chọn `Southeast Asia` (hoặc `East Asia`).
4. Nhấp nút **`Review + create`** phía dưới $\rightarrow$ Nhấp tiếp **`Create`**.

---

## BƯỚC 3: TẠO AZURE CONTAINER REGISTRY (ACR - KHO CHỨA IMAGE)
1. Gõ vào thanh tìm kiếm trên cùng: **`Container registries`** và nhấp chọn.
2. Nhấp nút **`+ Create`**.
3. Tại tab **Basics**, điền:
   - **Resource group:** Chọn `rg-cloud-supply-chain-demo` (vừa tạo ở bước 2).
   - **Registry name:** Gõ một tên viết liền không dấu, không viết hoa, duy nhất trên toàn thế giới *(Ví dụ: `demobyta` hoặc `acrdemoc5tiena2026`)*.
   - **Location:** `Southeast Asia`.
   - **SKU:** Chọn **`Basic`** *(Rất quan trọng: Chọn Basic để tiết kiệm tiền credit cho tài khoản sinh viên).*
4. Nhấp nút **`Review + create`** $\rightarrow$ Nhấp **`Create`**.
5. Chờ khoảng 30 giây để Azure tạo xong Registry.

---

## BƯỚC 4: TẠO AZURE KUBERNETES SERVICE (AKS - CỤM MÁY CHỦ KUBERNETES)
1. Gõ vào thanh tìm kiếm trên cùng: **`Kubernetes services`** và nhấp chọn.
2. Nhấp nút **`+ Create`** $\rightarrow$ Chọn **`Create a Kubernetes cluster`**.
3. Tại tab **Basics**:
   - **Resource group:** Chọn `rg-cloud-supply-chain-demo`.
   - **Cluster preset configuration:** Chọn **`Dev/Test ($)`** hoặc **`Free`**.
   - **Kubernetes cluster name:** Gõ `aks-supply-chain-demo`.
   - **Region:** `Southeast Asia`.
   - **Availability zones:** **Bỏ chọn tất cả (để trống không chọn Zone nào)** để tiết kiệm quota.
   - **Automatic upgrade & Node security channel:** Để tránh lỗi không cho chọn B-series, bạn có thể đổi 2 mục này sang `Disabled / None`.
   - **Node size (Kích thước máy ảo):** Nhấp vào **`Change size`** $\rightarrow$ Tìm và chọn **`Standard_D2s_v3`** (hoặc `Standard_D2as_v5` - 2 vCPU, 8 GiB RAM). *Nếu bạn đã tắt Automatic upgrade, bạn cũng có thể chọn `Standard_B2s`.*
   - **Scale method:** Chọn `Manual`.
   - **Node count (Số lượng Node):** Gõ số **`1`** *(Chỉ cần 1 node là đủ chạy demo, tránh vượt Quota vCPU).*
4. Nhấp chuyển sang tab **Integrations** (ở dải menu phía trên):
   - Tại mục **Container registry**, nhấp vào dropdown và chọn tên Registry bạn vừa tạo ở Bước 3 *(ví dụ `demobyta`)*.
   *(Bước này giúp AKS tự động được cấp quyền `AcrPull` để kéo image từ Registry về mà không bị lỗi quyền truy cập).*
5. Nhấp nút **`Review + create`** ở cuối trang $\rightarrow$ Nhấp **`Create`**.
6. **Lưu ý thời gian triển khai:** Quá trình Azure tạo cụm máy chủ Kubernetes mất từ **3 đến 5 phút**. Hãy chờ cho đến khi trang web hiện dòng chữ màu xanh lá **`Your deployment is complete`** rồi mới mở PowerShell để kết nối!

---

## BƯỚC 5: KẾT NỐI VÀ GHI LẠI TÊN TÀI NGUYÊN VÀO DỰ ÁN
Sau khi tạo xong trên Web Portal, bạn mở PowerShell tại thư mục `DemoC5` và gõ 2 lệnh sau để hệ thống ghi nhận tài nguyên:

1. Ghi tên Registry của bạn vào file `.acr_env`:
```powershell
Set-Content -Path "scripts\.acr_env" -Value "<TÊN_REGISTRY_CỦA_BẠN>.azurecr.io"
# Ví dụ: Set-Content -Path "scripts\.acr_env" -Value "demobyta.azurecr.io"
```

2. Tải cấu hình kết nối AKS về máy:
```powershell
az aks get-credentials --resource-group rg-cloud-supply-chain-demo --name aks-supply-chain-demo --overwrite-existing
```

👉 Từ đây, bạn chỉ cần chạy `.\scripts\02-build-sign.ps1` và `.\scripts\03-enforce-policy.ps1` là hoàn tất!
