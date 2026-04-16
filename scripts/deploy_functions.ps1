<# TexPilot - Supabase Edge Functions Deploy Betiği
   Tüm edge function'ları Supabase'e deploy eder.
   
   Ön koşul:
     - Supabase CLI yüklü olmalı (npm i -g supabase)
     - supabase login yapılmış olmalı
   
   Kullanım:
     .\scripts\deploy_functions.ps1              # Tüm fonksiyonları deploy et
     .\scripts\deploy_functions.ps1 -Function firma-olustur  # Tek fonksiyon deploy et
#>

param(
    [string]$Function = ""
)

$projectRoot = Split-Path $PSScriptRoot -Parent

# Supabase CLI kontrolü
$sbCli = Get-Command supabase -ErrorAction SilentlyContinue
if (-not $sbCli) {
    Write-Host "HATA: Supabase CLI bulunamadi!" -ForegroundColor Red
    Write-Host "  npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TexPilot Edge Functions Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$functions = @(
    "delete_user",
    "firma-olustur",
    "kullanici-davet", 
    "abonelik-kontrol",
    "odeme-webhook",
    "modul-aktivasyon",
    "platform-rapor"
)

Push-Location $projectRoot

if ($Function -ne "") {
    if ($functions -contains $Function) {
        Write-Host "Deploying: $Function" -ForegroundColor Yellow
        supabase functions deploy $Function
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  $Function basariyla deploy edildi" -ForegroundColor Green
        } else {
            Write-Host "  HATA: $Function deploy basarisiz" -ForegroundColor Red
        }
    } else {
        Write-Host "HATA: Bilinmeyen fonksiyon: $Function" -ForegroundColor Red
        Write-Host "Gecerli fonksiyonlar: $($functions -join ', ')" -ForegroundColor Gray
    }
} else {
    $success = 0
    $fail = 0
    foreach ($fn in $functions) {
        Write-Host "[$($functions.IndexOf($fn) + 1)/$($functions.Count)] Deploying: $fn" -ForegroundColor Yellow
        supabase functions deploy $fn
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Basarili" -ForegroundColor Green
            $success++
        } else {
            Write-Host "  BASARISIZ" -ForegroundColor Red
            $fail++
        }
    }
    Write-Host ""
    Write-Host "Sonuc: $success basarili, $fail basarisiz" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
}

Pop-Location
