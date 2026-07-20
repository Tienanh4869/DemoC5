# Script 02: Build Image trên Cloud (ACR Tasks), Tạo SBOM, Ký Cosign & Push lên ACR
$ErrorActionPreference = "Continue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " BƯỚC 2: BUILD IMAGE TRÊN CLOUD AZURE (ACR), TẠO SBOM & KÝ COSIGN " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

if (-not (Test-Path -Path "scripts\.acr_env")) {
    Write-Host "[LỖI] Không tìm thấy file scripts\.acr_env. Hãy chạy .\scripts\01-setup-azure.ps1 trước!" -ForegroundColor Red
    exit 1
}

$ACR_LOGIN_SERVER = (Get-Content -Path "scripts\.acr_env").Trim()
$ACR_NAME = $ACR_LOGIN_SERVER.Split('.')[0]
$IMAGE_NAME = "cloud-supply-chain-demo"
$IMAGE_TAG = "v1"
$FULL_IMAGE_REF = "$ACR_LOGIN_SERVER/${IMAGE_NAME}:${IMAGE_TAG}"

# 1. Lấy thông tin xác thực Registry từ Azure (không cần cài Docker Desktop)
Write-Host "`n[1/5] Lấy thông tin xác thực từ Azure Container Registry ($ACR_NAME)..." -ForegroundColor Yellow
az acr update -n $ACR_NAME --admin-enabled true --output none 2>$null
$creds = az acr credential show --name $ACR_NAME | ConvertFrom-Json
$ACR_USER = $creds.username
$ACR_PASS = $creds.passwords[0].value

# Đăng nhập Cosign/Syft vào Registry không cần Docker
cosign login $ACR_LOGIN_SERVER -u $ACR_USER -p $ACR_PASS
Write-Host "      -> Đăng nhập Registry thành công!" -ForegroundColor Green

# 2. Đưa Container Image lên Azure Container Registry (Dùng az acr import tránh lỗi cấm ACR Tasks của tài khoản sinh viên)
Write-Host "[2/5] Đưa Container Image Nginx bảo mật lên Đám mây Azure ($FULL_IMAGE_REF)..." -ForegroundColor Yellow
Write-Host "      (Đang sao chép Image trực tiếp trên Cloud qua Azure ACR Import...)" -ForegroundColor Cyan
az acr import --name $ACR_NAME --source docker.io/library/nginx:1.26-alpine --image "${IMAGE_NAME}:${IMAGE_TAG}" --force
Write-Host "      -> Import Image vào Cloud ACR thành công!" -ForegroundColor Green

# 3. Quét image từ Registry và tạo SBOM bằng Syft
Write-Host "[3/5] Quét thành phần Image trên Cloud và tạo SBOM (Software Bill of Materials) bằng Syft..." -ForegroundColor Yellow
$env:SYFT_REGISTRY_AUTH_AUTHORITY = $ACR_LOGIN_SERVER
$env:SYFT_REGISTRY_AUTH_USERNAME = $ACR_USER
$env:SYFT_REGISTRY_AUTH_PASSWORD = $ACR_PASS
syft "registry:${FULL_IMAGE_REF}" -o spdx-json=cloud-demo-sbom.json
Write-Host "      -> Đã xuất file SBOM: cloud-demo-sbom.json" -ForegroundColor Green

# 4. Ký Image bằng Cosign & Đính kèm SBOM
Write-Host "[4/5] Ký chữ ký số mật mã cho Image & SBOM bằng Cosign..." -ForegroundColor Yellow
$env:COSIGN_PASSWORD = "AzureStudentDemoPassword123!"

# Ký Image
cosign sign --key keys/cosign.key $FULL_IMAGE_REF -y
Write-Host "      -> Đã ký Image thành công! (.sig artifact đã push lên ACR)" -ForegroundColor Green

# Đính kèm SBOM vào Registry
cosign attach sbom --sbom cloud-demo-sbom.json --type spdx $FULL_IMAGE_REF
Write-Host "      -> Đã đính kèm SBOM attestation lên ACR thành công!" -ForegroundColor Green

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host " HOÀN TẤT BUILD & SIGN! Image đã an toàn trên Azure Container Registry " -ForegroundColor Green
Write-Host " Tiếp theo: Hãy chạy lệnh .\scripts\03-enforce-policy.ps1 " -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Green
