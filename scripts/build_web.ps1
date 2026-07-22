<# TexPilot - Web Build & Deploy Betiği
   Flutter web uygulamasını üretim ortamı için derler.
   
   Kullanım:
     .\scripts\build_web.ps1                    # Varsayılan (production)
     .\scripts\build_web.ps1 -Env staging       # Staging ortamı
     .\scripts\build_web.ps1 -Env production     # Production ortamı
#>

param(
    [ValidateSet("production", "staging")]
    [string]$Env = "production",
    [switch]$Deploy
)

$projectRoot = Split-Path $PSScriptRoot -Parent
$envCandidates = if ($Env -eq "production") {
    @(".env.production.local", ".env.production", ".env.local", ".env")
} else {
    @(".env.staging.local", ".env.staging")
}
$envFile = $envCandidates |
    ForEach-Object { Join-Path $projectRoot $_ } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($envFile)) {
    Write-Host "HATA: $Env ortam dosyasi bulunamadi!" -ForegroundColor Red
    Write-Host "  Aranan dosyalar: $($envCandidates -join ', ')" -ForegroundColor Yellow
    exit 1
}

$envValues = @{}
Get-Content -LiteralPath $envFile | ForEach-Object {
    if ($_ -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        $envValues[$matches[1]] = $matches[2].Trim()
    }
}
foreach ($requiredKey in @("SUPABASE_URL", "SUPABASE_ANON_KEY")) {
    if (-not $envValues.ContainsKey($requiredKey) -or
        [string]::IsNullOrWhiteSpace($envValues[$requiredKey])) {
        Write-Host "HATA: $envFile icinde $requiredKey eksik!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TexPilot Web Build ($Env)" -ForegroundColor Cyan
Write-Host " Ortam dosyasi: $(Split-Path $envFile -Leaf)" -ForegroundColor Gray
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
    --pwa-strategy=none

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
if ($Deploy) {
    Write-Host "[5/5] Vercel prebuilt production deploy hazirlaniyor..." -ForegroundColor Yellow
    $vercelOutput = Join-Path $projectRoot ".vercel\output"
    $vercelStatic = Join-Path $vercelOutput "static"
    $vercelConfig = Join-Path $vercelOutput "config.json"

    New-Item -ItemType Directory -Path $vercelStatic -Force | Out-Null
    Copy-Item -Path (Join-Path $buildDir "*") -Destination $vercelStatic -Recurse -Force

    $noCacheHeaders = @{ "Cache-Control" = "no-cache, no-store, must-revalidate" }
    $vercelBuildConfig = @{
        version = 3
        routes = @(
            @{ src = "/flutter_service_worker.js"; headers = $noCacheHeaders; continue = $true },
            @{ src = "/flutter_bootstrap.js"; headers = $noCacheHeaders; continue = $true },
            @{ src = "/flutter.js"; headers = $noCacheHeaders; continue = $true },
            @{ src = "/main.dart.js"; headers = $noCacheHeaders; continue = $true },
            @{ src = "/index.html"; headers = $noCacheHeaders; continue = $true },
            @{ src = "/version.json"; headers = $noCacheHeaders; continue = $true },
            @{ handle = "filesystem" },
            @{ src = "/.*"; dest = "/index.html" }
        )
    }
    $vercelBuildConfig | ConvertTo-Json -Depth 6 -Compress |
        Set-Content -LiteralPath $vercelConfig -Encoding utf8

    Push-Location $projectRoot
    try {
        vercel deploy --prebuilt --prod --yes
        if ($LASTEXITCODE -ne 0) {
            Write-Host "HATA: Vercel deploy basarisiz" -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Production deploy icin:" -ForegroundColor Cyan
    Write-Host "  .\scripts\build_web.ps1 -Env production -Deploy" -ForegroundColor Gray
}
