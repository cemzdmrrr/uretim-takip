<# TexPilot - Geliştirme Çalıştırma Betiği
   .env dosyasını okuyarak --dart-define-from-file ile uygulamayı başlatır.
   Kullanım: .\scripts\run_dev.ps1
#>

$envFile = Join-Path $PSScriptRoot '..\.env'

if (-not (Test-Path $envFile)) {
    Write-Host "HATA: .env dosyasi bulunamadi!" -ForegroundColor Red
    Write-Host "  .env.example dosyasini .env olarak kopyalayin ve gercek degerleri girin." -ForegroundColor Yellow
    Write-Host "  Ornek: Copy-Item .env.example .env" -ForegroundColor Gray
    exit 1
}

Write-Host "TexPilot baslatiliyor (.env yuklenecek)..." -ForegroundColor Green
flutter run --dart-define-from-file="$envFile"
