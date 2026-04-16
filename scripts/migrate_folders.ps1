<#
  TexPilot - Klasör Yapısı Düzenleme Betiği
  lib/ kökündeki dosyaları feature-based klasörlere taşır ve import yollarını günceller.
#>
$ErrorActionPreference = 'Stop'
$libDir = 'c:\uretim_takip\lib'

# ──────────────────────────────────────────────────
# 1) Boş/duplicate dosyaları sil
# ──────────────────────────────────────────────────
$emptyFiles = @(
    'kasa_banka_model.dart',
    'kasa_banka_hareket_model.dart'
)
foreach ($f in $emptyFiles) {
    $path = "$libDir\$f"
    if ((Test-Path $path) -and (Get-Item $path).Length -eq 0) {
        Remove-Item $path -Force
        Write-Host "  Silindi (bos): $f" -ForegroundColor DarkGray
    }
}

# ──────────────────────────────────────────────────
# 2) Dosya -> hedef klasör eşlemesi  (lib-göreli)
# ──────────────────────────────────────────────────
$folderMap = @{
    # ─── auth ───
    'login_page.dart'           = 'pages/auth'
    'register_page.dart'        = 'pages/auth'
    'splash_screen.dart'        = 'pages/auth'

    # ─── home ───
    'ana_sayfa.dart'            = 'pages/home'
    'dashboard_page.dart'       = 'pages/home'

    # ─── uretim (production dashboards) ───
    'dokuma_dashboard.dart'                = 'pages/uretim'
    'dokuma_dashboard_aksiyonlar.dart'      = 'pages/uretim'
    'dokuma_dashboard_detay.dart'           = 'pages/uretim'
    'dokuma_dashboard_dialog.dart'          = 'pages/uretim'
    'dokuma_dashboard_rapor.dart'           = 'pages/uretim'
    'dokuma_dashboard_widgets.dart'         = 'pages/uretim'
    'konfeksiyon_dashboard.dart'            = 'pages/uretim'
    'yikama_dashboard.dart'                 = 'pages/uretim'
    'nakis_dashboard.dart'                  = 'pages/uretim'
    'ilik_dugme_dashboard.dart'             = 'pages/uretim'
    'utu_dashboard.dart'                    = 'pages/uretim'
    'utu_paket_dashboard.dart'              = 'pages/uretim'
    'utu_paket_aksiyonlar.dart'             = 'pages/uretim'
    'utu_paket_ceki.dart'                   = 'pages/uretim'
    'utu_paket_ceki_islemleri.dart'         = 'pages/uretim'
    'utu_paket_dialoglar.dart'              = 'pages/uretim'
    'utu_paket_paketleme.dart'              = 'pages/uretim'
    'paketleme_dashboard.dart'              = 'pages/uretim'
    'kalite_kontrol_dashboard.dart'         = 'pages/uretim'
    'kalite_kontrol_panel.dart'             = 'pages/uretim'
    'kalite_kontrol_panel_widgets.dart'     = 'pages/uretim'
    'kalite_panel.dart'                     = 'pages/uretim'
    'uretim_asama_dashboard.dart'           = 'pages/uretim'
    'uretim_asama_aksiyonlar.dart'          = 'pages/uretim'
    'uretim_asama_dashboard_dialog.dart'    = 'pages/uretim'
    'uretim_asama_rapor.dart'               = 'pages/uretim'
    'uretim_raporu_page.dart'               = 'pages/uretim'
    'uretim_raporu_filtreler.dart'          = 'pages/uretim'
    'uretim_raporu_tabs.dart'               = 'pages/uretim'

    # ─── model (model management) ───
    'model_listele.dart'                    = 'pages/model'
    'model_listele_export.dart'             = 'pages/model'
    'model_listele_toplu.dart'              = 'pages/model'
    'model_ekle.dart'                       = 'pages/model'
    'model_ekle_bilgiler.dart'              = 'pages/model'
    'model_ekle_fiyatlandirma.dart'         = 'pages/model'
    'model_ekle_new.dart'                   = 'pages/model'
    'model_detay.dart'                      = 'pages/model'
    'model_detay_admin.dart'                = 'pages/model'
    'model_detay_aksesuar.dart'             = 'pages/model'
    'model_detay_bilgiler.dart'             = 'pages/model'
    'model_detay_durum.dart'                = 'pages/model'
    'model_detay_fiyatlandirma.dart'        = 'pages/model'
    'model_detay_uretim.dart'               = 'pages/model'
    'model_detay_yukleme.dart'              = 'pages/model'
    'model_detay_utils.dart'                = 'pages/model'
    'model_duzenle.dart'                    = 'pages/model'
    'toplu_model_ekle.dart'                 = 'pages/model'
    'dokuma_goruntuleme_detay.dart'         = 'pages/model'

    # ─── personel (HR) ───
    'personel_anasayfa.dart'                = 'pages/personel'
    'personel_listesi_page.dart'            = 'pages/personel'
    'personel_ekle_page.dart'               = 'pages/personel'
    'personel_detay_page.dart'              = 'pages/personel'
    'personel_ayarlar_page.dart'            = 'pages/personel'
    'personel_arsiv_page.dart'              = 'pages/personel'
    'personel_arsiv_page_logic.dart'        = 'pages/personel'
    'personel_analiz_page.dart'             = 'pages/personel'
    'personel_analiz_widgets.dart'          = 'pages/personel'

    # ─── muhasebe (accounting) ───
    'muhasebe_yonetimi_page.dart'           = 'pages/muhasebe'
    'fatura_listesi_page.dart'              = 'pages/muhasebe'
    'fatura_ekle_page.dart'                 = 'pages/muhasebe'
    'fatura_ekle_page_widgets.dart'         = 'pages/muhasebe'
    'fatura_detay_page.dart'                = 'pages/muhasebe'
    'fatura_detay_page_widgets.dart'        = 'pages/muhasebe'
    'kasa_banka_listesi_page.dart'          = 'pages/muhasebe'
    'kasa_banka_ekle_page.dart'             = 'pages/muhasebe'
    'kasa_banka_detay_page.dart'            = 'pages/muhasebe'
    'kasa_banka_hareket_listesi_page.dart'  = 'pages/muhasebe'
    'kasa_banka_hareket_ekle_page.dart'     = 'pages/muhasebe'
    'kasa_banka_hareket_detay_page.dart'    = 'pages/muhasebe'
    'odeme_page.dart'                       = 'pages/muhasebe'
    'odeme_page_aksiyonlar.dart'            = 'pages/muhasebe'
    'bordro_page.dart'                      = 'pages/muhasebe'
    'bordro_hesaplama_page.dart'            = 'pages/muhasebe'
    'mesai_page.dart'                       = 'pages/muhasebe'
    'mesai_puantaj_page.dart'               = 'pages/muhasebe'
    'puantaj_tablo_page.dart'               = 'pages/muhasebe'
    'izin_page.dart'                        = 'pages/muhasebe'
    'donem_yonetimi.dart'                   = 'pages/muhasebe'

    # ─── tedarikci (suppliers) ───
    'tedarikci_panel.dart'                  = 'pages/tedarikci'
    'tedarikci_panel_aksiyonlar.dart'       = 'pages/tedarikci'
    'tedarikci_listesi_page.dart'           = 'pages/tedarikci'
    'tedarikci_ekle_page.dart'              = 'pages/tedarikci'
    'tedarikci_detay_page.dart'             = 'pages/tedarikci'

    # ─── stok (inventory) ───
    'stok_yonetimi.dart'                            = 'pages/stok'
    'stok_yonetimi_aksesuarlar.dart'                = 'pages/stok'
    'stok_yonetimi_aksesuarlar_coklu_beden.dart'    = 'pages/stok'
    'stok_yonetimi_aksesuarlar_dialog.dart'          = 'pages/stok'
    'urun_depo_yonetimi.dart'                       = 'pages/stok'
    'urun_depo_yonetimi_dialog.dart'                = 'pages/stok'
    'iplik_stoklari.dart'                           = 'pages/stok'
    'iplik_stoklari_crud.dart'                      = 'pages/stok'
    'iplik_stoklari_detay.dart'                     = 'pages/stok'
    'iplik_stoklari_siparis.dart'                   = 'pages/stok'
    'iplik_siparis_takip_page.dart'                 = 'pages/stok'

    # ─── sevkiyat (shipping) ───
    'sevk_yonetimi_page.dart'               = 'pages/sevkiyat'
    'sevk_yonetimi_admin.dart'              = 'pages/sevkiyat'
    'sevk_yonetimi_tabs.dart'               = 'pages/sevkiyat'
    'sevkiyat_panel.dart'                   = 'pages/sevkiyat'
    'sevkiyat_panel_widgets.dart'           = 'pages/sevkiyat'
    'sevkiyat_olustur_page.dart'            = 'pages/sevkiyat'
    'sofor_panel.dart'                      = 'pages/sevkiyat'
    'tamamlanan_siparisler_page.dart'       = 'pages/sevkiyat'

    # ─── raporlar (reports) ───
    'raporlar_page.dart'                    = 'pages/raporlar'
    'gelismis_raporlar_page.dart'           = 'pages/raporlar'
    'gelismis_raporlar_export.dart'         = 'pages/raporlar'
    'gelismis_raporlar_kalite.dart'         = 'pages/raporlar'
    'gelismis_raporlar_sevkiyat.dart'       = 'pages/raporlar'
    'gelismis_raporlar_stok.dart'           = 'pages/raporlar'
    'gelismis_raporlar_tabs.dart'           = 'pages/raporlar'
    'advanced_reports_page.dart'            = 'pages/raporlar'
    'advanced_reports_content.dart'         = 'pages/raporlar'

    # ─── ayarlar (settings/admin) ───
    'sistem_ayarlari_page.dart'             = 'pages/ayarlar'
    'kullanici_listesi.dart'                = 'pages/ayarlar'
    'kullanici_listesi_ui.dart'             = 'pages/ayarlar'
    'admin_test_page.dart'                  = 'pages/ayarlar'
    'bildirimler_page.dart'                 = 'pages/ayarlar'
    'dosyalar_page.dart'                    = 'pages/ayarlar'

    # ─── models (root → models/) ───
    'fatura_model.dart'                     = 'models'
    'fatura_kalemi_model.dart'              = 'models'
    'odeme_model.dart'                      = 'models'
    'siparis_model.dart'                    = 'models'
    'mesai_model.dart'                      = 'models'
    'puantaj_model.dart'                    = 'models'
    'izin_model.dart'                       = 'models'
    'personel_model.dart'                   = 'models'
    'tedarikci_model.dart'                  = 'models'
    'notification_model.dart'               = 'models'

    # ─── utils (data transfer files) ───
    'toplu_aktar_web.dart'                  = 'utils'
    'toplu_aktar_web_stub.dart'             = 'utils'
    'toplu_aktar_web_web.dart'              = 'utils'
}

# ──────────────────────────────────────────────────
# 3) Klasörleri oluştur
# ──────────────────────────────────────────────────
$folderMap.Values | Sort-Object -Unique | ForEach-Object {
    $dir = "$libDir\$($_ -replace '/',  '\')"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Klasor: $_" -ForegroundColor Cyan
    }
}

# ──────────────────────────────────────────────────
# 4) Tam yol haritası  (eski lib-göreli → yeni lib-göreli)
# ──────────────────────────────────────────────────
$pathMap = @{}   # old lib-relative  →  new lib-relative
foreach ($entry in $folderMap.GetEnumerator()) {
    $old = $entry.Key                         # e.g. login_page.dart
    $new = "$($entry.Value)/$($entry.Key)"    # e.g. pages/auth/login_page.dart
    $pathMap[$old] = $new
}

# ──────────────────────────────────────────────────
# 5) Dosyaları taşı
# ──────────────────────────────────────────────────
$moved = 0
foreach ($entry in $pathMap.GetEnumerator()) {
    $src = "$libDir\$($entry.Key)"
    $dst = "$libDir\$($entry.Value -replace '/', '\')"
    if (Test-Path $src) {
        Move-Item $src $dst -Force
        $moved++
    }
}
Write-Host "`n  Tasinan dosya: $moved" -ForegroundColor Green

# ──────────────────────────────────────────────────
# 6) Tüm .dart dosyalarının konum haritasını oluştur (dosyaAdı → lib-göreli yol)
# ──────────────────────────────────────────────────
$allFiles = @{}
Get-ChildItem -Recurse -Filter *.dart $libDir | ForEach-Object {
    $rel = $_.FullName.Substring($libDir.Length + 1).Replace('\', '/')
    $allFiles[$_.Name] = $rel
}

# ──────────────────────────────────────────────────
# 7) import yollarını güncelle (tüm .dart dosyalarında)
# ──────────────────────────────────────────────────
$fixCount = 0
Get-ChildItem -Recurse -Filter *.dart $libDir | ForEach-Object {
    $file = $_
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $original = $content

    # Relative import pattern:  import 'xxx.dart';  or  import 'folder/xxx.dart';
    $content = [regex]::Replace($content, "import '(?!package:|dart:)([^']+)';", {
        param($m)
        $importPath = $m.Groups[1].Value
        $fileName = [System.IO.Path]::GetFileName($importPath)
        
        # Resolve the imported file's current lib-relative path
        if ($allFiles.ContainsKey($fileName)) {
            $newLibPath = $allFiles[$fileName]
            return "import 'package:uretim_takip/$newLibPath';"
        }
        # Couldn't resolve — keep original
        return $m.Value
    })

    # Also fix existing package:uretim_takip imports that point to old paths
    foreach ($entry in $pathMap.GetEnumerator()) {
        $oldPkg = "package:uretim_takip/$($entry.Key)"
        $newPkg = "package:uretim_takip/$($entry.Value)"
        $content = $content.Replace("'$oldPkg'", "'$newPkg'")
    }

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        $fixCount++
    }
}
Write-Host "  Guncellenen dosya: $fixCount" -ForegroundColor Green

Write-Host "`nMigrasyon tamamlandi!" -ForegroundColor Yellow
