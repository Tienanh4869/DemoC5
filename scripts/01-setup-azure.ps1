# Script 01: Khởi tạo Hạ tầng Azure (ACR + AKS B2s cho Azure Student) & Key Pair
$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " BƯỚC 1: KHỞI TẠO HẠ TẦNG AZURE CLOUD (ACR + AKS AZURE STUDENT) " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$RESOURCE_GROUP = "rg-cloud-supply-chain-demo"
$LOCATION = "southeastasia" # Hoặc eastasia nếu southeastasia bị hết quota
$RANDOM_SUFFIX = -join ((48..57) + (97..122) | Get-Random -Count 6 | % {[char]$_})
$ACR_NAME = "acrdemoc5$RANDOM_SUFFIX"
$AKS_NAME = "aks-supply-chain-demo"

# 1. Tạo Resource Group
Write-Host "`n[1/5] Kiểm tra / Tạo Resource Group '$RESOURCE_GROUP' tại '$LOCATION'..." -ForegroundColor Yellow
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# 2. Tạo Azure Container Registry (Basic SKU tiết kiệm credit)
Write-Host "[2/5] Tạo Azure Container Registry '$ACR_NAME' (Basic SKU)..." -ForegroundColor Yellow
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true --output none
$ACR_LOGIN_SERVER = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv

# Lưu lại tên ACR vào file .env để các script sau tự động đọc
Set-Content -Path "scripts\.acr_env" -Value "$ACR_LOGIN_SERVER"
Write-Host "      -> Registry created: $ACR_LOGIN_SERVER" -ForegroundColor Green

# 3. Tạo Azure Kubernetes Service (AKS) - dùng Standard_B2s tiết kiệm vCPU Quota
Write-Host "[3/5] Tạo AKS Cluster '$AKS_NAME' (VM Standard_B2s)... Quá trình này mất khoảng 3-5 phút..." -ForegroundColor Yellow
az aks create `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_NAME `
    --node-count 1 `
    --node-vm-size Standard_B2s `
    --generate-ssh-keys `
    --attach-acr $ACR_NAME `
    --output none

Write-Host "      -> AKS Cluster created & attached to ACR!" -ForegroundColor Green

# 4. Lấy cấu hình Kubeconfig để dùng kubectl
Write-Host "[4/5] Kết nối kubectl với cụm AKS..." -ForegroundColor Yellow
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# 5. Tạo cặp khóa Cosign (Key Pair)
Write-Host "[5/5] Khởi tạo cặp khóa bảo mật Cosign (Private/Public keys)..." -ForegroundColor Yellow
if (-not (Test-Path -Path "keys")) {
    New-Item -ItemType Directory -Path "keys" | Out-Null
}

if (-not (Test-Path -Path "keys\cosign.key")) {
    $env:COSIGN_PASSWORD = "AzureStudentDemoPassword123!"
    cosign generate-key-pair --output-key-prefix keys/cosign
    Write-Host "      -> Cặp khóa đã tạo thành công trong thư mục keys/" -ForegroundColor Green
} else {
    Write-Host "      -> Cặp khóa đã tồn tại trong thư mục keys/, bỏ qua tạo mới." -ForegroundColor Green
}

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host " HOÀN TẤT KHỞI TẠO HẠ TẦNG! ACR Login Server: $ACR_LOGIN_SERVER " -ForegroundColor Green
Write-Host " Tiếp theo: Hãy chạy lệnh .\scripts\02-build-sign.ps1 " -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Green
