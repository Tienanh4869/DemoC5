# Script 03: Thiết lập Kyverno Policy trên AKS và kiểm thử kịch bản Pass/Fail
$ErrorActionPreference = "Continue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " BƯỚC 3: THIẾT LẬP POLICY ENFORCEMENT & TEST KỊCH BẢN DEMO TRÊN AKS " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

if (-not (Test-Path -Path "scripts\.acr_env")) {
    Write-Host "[LỖI] Không tìm thấy file scripts\.acr_env. Hãy chạy .\scripts\01-setup-azure.ps1 trước!" -ForegroundColor Red
    exit 1
}

$ACR_LOGIN_SERVER = (Get-Content -Path "scripts\.acr_env").Trim()
$IMAGE_NAME = "cloud-supply-chain-demo"
$IMAGE_TAG = "v1"
$FULL_IMAGE_REF = "$ACR_LOGIN_SERVER/${IMAGE_NAME}:${IMAGE_TAG}"

# 1. Cài đặt Kyverno Admission Controller lên AKS
Write-Host "`n[1/5] Cài đặt Kyverno Policy Engine lên cụm Kubernetes..." -ForegroundColor Yellow
kubectl apply --server-side --force-conflicts -f https://github.com/kyverno/kyverno/releases/download/v1.11.4/install.yaml 2>&1 | Out-Null
Write-Host "      -> Đang chờ các Pod của Kyverno khởi tạo (khoảng 30-60 giây)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
kubectl wait --namespace kyverno --for=condition=ready pod --selector app.kubernetes.io/name=kyverno --timeout=120s 2>$null | Out-Null
Write-Host "      -> Kyverno Admission Controller đã sẵn sàng!" -ForegroundColor Green

# 2. Tạo Policy Kyverno với Public Key thực tế của bạn
Write-Host "[2/5] Cấu hình Policy xác thực chữ ký Cosign trên AKS..." -ForegroundColor Yellow
if (-not (Test-Path -Path "policies")) {
    New-Item -ItemType Directory -Path "policies" | Out-Null
}

$PUBLIC_KEY_CONTENT = Get-Content -Path "keys\cosign.pub" -Raw
$PUBLIC_KEY_INDENTED = $PUBLIC_KEY_CONTENT.Trim() -replace '(?m)^', '                        '

$POLICY_YAML = @"
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-cosign-signature
  annotations:
    policies.kyverno.io/title: Verify Cosign Image Signature
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: >-
      Chặn mọi Pod triển khai nếu container image từ ACR không có chữ ký hợp lệ
      từ Public Key được cấp phép.
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: verify-signature
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - default
              - production
      verifyImages:
        - imageReferences:
            - "*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
$PUBLIC_KEY_INDENTED
"@

Set-Content -Path "policies\verify-cosign-policy.yaml" -Value $POLICY_YAML -Encoding UTF8
kubectl apply -f policies/verify-cosign-policy.yaml | Out-Null
Write-Host "      -> Đã áp dụng ClusterPolicy: verify-image-cosign-signature (Chế độ ENFORCE)" -ForegroundColor Green

# 3. Tạo YAML Test cases
# Case 1: Image giả mạo / chưa ký (dùng nginx:latest từ DockerHub nhưng trỏ nhầm hoặc image chưa ký)
$INVALID_YAML = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-invalid-unsigned
  labels:
    app: demo-invalid
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-invalid
  template:
    metadata:
      labels:
        app: demo-invalid
    spec:
      containers:
      - name: web
        # Giả lập image lạ từ ACR hoặc image chưa được ký
        image: $ACR_LOGIN_SERVER/unauthorized-hacker-app:latest
        imagePullPolicy: Always
"@
Set-Content -Path "policies\deploy-invalid.yaml" -Value $INVALID_YAML

# Case 2: Image hợp lệ đã ký
$VALID_YAML = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-supply-chain-demo
  labels:
    app: secure-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-demo
  template:
    metadata:
      labels:
        app: secure-demo
    spec:
      containers:
      - name: web-dashboard
        image: $FULL_IMAGE_REF
        imagePullPolicy: Always
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-volume
        configMap:
          name: web-dashboard-content
---
apiVersion: v1
kind: Service
metadata:
  name: cloud-supply-chain-demo
spec:
  type: ClusterIP
  selector:
    app: secure-demo
  ports:
  - port: 80
    targetPort: 80
"@
Set-Content -Path "policies\deploy-valid.yaml" -Value $VALID_YAML -Encoding UTF8

# 4. CHẠY TEST CASE 1: THỬ DEPLOY IMAGE CHƯA KÝ (BỊ CHẶN)
Write-Host "`n[3/5] TEST CASE 1: Thử triển khai Image CHƯA ĐƯỢC KÝ ($ACR_LOGIN_SERVER/unauthorized-hacker-app:latest)..." -ForegroundColor Yellow
$errorOutput = kubectl apply -f policies/deploy-invalid.yaml 2>&1
if ($errorOutput -match "denied the request" -or $errorOutput -match "failed") {
    Write-Host "      [THÀNH CÔNG!] Kubernetes đã CHẶN thành công Pod không hợp lệ!" -ForegroundColor Green
    Write-Host "      [Chi tiết lỗi Admission Controller]: $errorOutput" -ForegroundColor Red
} else {
    Write-Host "      [CHÚ Ý] Lệnh apply không trả về lỗi chặn ngay lập tức." -ForegroundColor Yellow
}

# 5. CHẠY TEST CASE 2: DEPLOY IMAGE HỢP LỆ (ĐÃ KÝ)
Write-Host "`n[4/5] TEST CASE 2: Triển khai Image ĐÃ ĐƯỢC KÝ HỢP LỆ ($FULL_IMAGE_REF)..." -ForegroundColor Yellow
kubectl delete configmap web-dashboard-content --ignore-not-found=true 2>&1 | Out-Null
kubectl create configmap web-dashboard-content --from-file=app/ 2>&1 | Out-Null
kubectl apply -f policies/deploy-valid.yaml
Write-Host "      -> Đang chờ Pod khởi động thành công..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
kubectl get pods -l app=secure-demo

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host " CHÚC MỪNG! DEMO HOÀN TẤT THÀNH CÔNG TRÊN AZURE KUBERNETES SERVICE " -ForegroundColor Green
Write-Host " Để mở Web Dashboard trên trình duyệt, hãy chạy lệnh sau: " -ForegroundColor Cyan
Write-Host " kubectl port-forward service/cloud-supply-chain-demo 8080:80 " -ForegroundColor White
Write-Host " Sau đó truy cập: http://localhost:8080 " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Green
