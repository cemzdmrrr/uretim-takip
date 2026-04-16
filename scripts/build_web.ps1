<# TexPilot - Web Build & Deploy Betiği
   Flutter web uygulamasını üretim ortamı için derler.
   
   Kullanım:
     .\scripts\build_web.ps1                    # Varsayılan (production)
     .\scripts\build_web.ps1 -Env staging       # Staging ortamı
     .\scripts\build_web.ps1 -Env production     # Production ortamı
#>

param(
    [ValidateSet("production", "staging")]
    [string]$Env = "production"
)

$projectRoot = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $projectRoot ".env.$Env"

if (-not (Test-Path $envFile)) {
    Write-Host "HATA: $envFile dosyasi bulunamadi!" -ForegroundColor Red
    Write-Host "  .env.production.example dosyasini .env.$Env olarak kopyalayin." -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TexPilot Web Build ($Env)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Flutter temizlik
Write-Host "[1/4] Flutter temizleniyor..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) { Write-Host "HATA: flutter clean basarisiz" -ForegroundColor Red; exit 1 }

# Bağımlılıkları indir
Write-Host "[2/4] Bagimliliklar indiriliyor..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "HATA: flutter pub get basarisiz" -ForegroundColor Red; exit 1 }

# Web build
Write-Host "[3/4] Web build olusturuluyor..." -ForegroundColor Yellow
flutter build web `
    --release `
    --dart-define-from-file="$envFile" `
    --base-href="/" `
    --web-renderer=canvaskit

if ($LASTEXITCODE -ne 0) { Write-Host "HATA: flutter build web basarisiz" -ForegroundColor Red; exit 1 }

# Build bilgileri
$buildDir = Join-Path $projectRoot "build\web"
$buildSize = (Get-ChildItem -Path $buildDir -Recurse | Measure-Object -Property Length -Sum).Sum
$buildSizeMB = [math]::Round($buildSize / 1MB, 2)

Write-Host ""
Write-Host "[4/4] Build tamamlandi!" -ForegroundColor Green
Write-Host "  Cikti: $buildDir" -ForegroundColor Gray
Write-Host "  Boyut: $buildSizeMB MB" -ForegroundColor Gray
Write-Host ""
Write-Host "Deploy icin build/web klasorunu hosting servisinize yukleyin." -ForegroundColor Cyan
Write-Host "  Firebase  : firebase deploy --only hosting" -ForegroundColor Gray
Write-Host "  Vercel    : vercel --prod" -ForegroundColor Gray
Write-Host "  Netlify   : netlify deploy --prod --dir=build/web" -ForegroundColor Gray
