# Download Gemma 4 E2B model for Gemma-SOS (2.46 GB)
# Usage: powershell -ExecutionPolicy Bypass -File scripts/download_model.ps1

$ModelDir = "assets\models"
$ModelFile = "gemma-4-E2B-it.litertlm"
$ModelUrl = "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm"

Write-Host "[*] Downloading Gemma 4 E2B model (2.46 GB)..." -ForegroundColor Cyan
Write-Host "[*] Source: $ModelUrl" -ForegroundColor Cyan

# Create directory if needed
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null

# Download using Invoke-WebRequest
Write-Host "[*] Downloading..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $ModelUrl -OutFile "$ModelDir\$ModelFile" -UseBasicParsing -Verbose
} catch {
    Write-Host "[!] Download failed: $_" -ForegroundColor Red
    exit 1
}

# Verify
if (Test-Path "$ModelDir\$ModelFile") {
    $Size = (Get-Item "$ModelDir\$ModelFile").Length / 1GB
    Write-Host "[+] Model downloaded: $ModelDir\$ModelFile ($([math]::Round($Size, 2)) GB)" -ForegroundColor Green
} else {
    Write-Host "[!] Download failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "To push to Android device via ADB:" -ForegroundColor Cyan
Write-Host "  adb push $ModelDir\$ModelFile /sdcard/Download/" -ForegroundColor White
Write-Host ""
Write-Host "Note: The old .task file in assets/models/ is for Gemma3n." -ForegroundColor Yellow
Write-Host "Gemma 4 REQUIRES the .litertlm format." -ForegroundColor Yellow
