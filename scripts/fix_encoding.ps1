$filePath = "c:\uretim_takip\lib\pages\stok\urun_depo_yonetimi_dialog.dart"
$c = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$r = [char]0xFFFD

$before = ($c.ToCharArray() | Where-Object { $_ -eq $r }).Count
Write-Host "Before: $before replacement chars"

# === MULTI-WORD PHRASES (longest/most specific first) ===

# "Bu ürünü silmek istediğinizden emin misiniz?"
$c = $c.Replace("Bu ${r}r${r}n${r} silmek istedi${r}inizden emin misiniz?", "Bu ürünü silmek istediğinizden emin misiniz?")

# "Tamamlanmış sipariş bulunamadı"
$c = $c.Replace("Tamamlanm${r}${r} sipari${r} bulunamad${r}", "Tamamlanmış sipariş bulunamadı")

# "Açıklama (İsteğe Bağlı)"
$c = $c.Replace("A${r}${r}klama (${r}ste${r}e Ba${r}l${r})", "Açıklama (İsteğe Bağlı)")

# "Bu model için renk bilgisi bulunamadı"
$c = $c.Replace("Bu model i${r}in renk bilgisi bulunamad${r}", "Bu model için renk bilgisi bulunamadı")

# "En fazla ... adet satılabilir"
$c = $c.Replace("adet sat${r}labilir", "adet satılabilir")

# "Henüz $kaliteTipi ürün eklenmedi"
$c = $c.Replace("Hen${r}z `$kaliteTipi ${r}r${r}n eklenmedi", "Henüz `$kaliteTipi ürün eklenmedi")

# "Benzersiz model listesi oluştur"
$c = $c.Replace("Benzersiz model listesi olu${r}tur", "Benzersiz model listesi oluştur")

# "Lütfen marka seçin"
$c = $c.Replace("L${r}tfen marka se${r}in", "Lütfen marka seçin")

# "Lütfen model seçin" 
$c = $c.Replace("L${r}tfen model se${r}in", "Lütfen model seçin")

# "Lütfen adet girin"
$c = $c.Replace("L${r}tfen adet girin", "Lütfen adet girin")

# "Lütfen tutar girin"
$c = $c.Replace("L${r}tfen tutar girin", "Lütfen tutar girin")

# "Açıklama ile ara..."
$c = $c.Replace("A${r}${r}klama ile ara...", "Açıklama ile ara...")

# "Kaç adet satıldı?"
$c = $c.Replace("Ka${r} adet sat${r}ld${r}?", "Kaç adet satıldı?")

# "Geçerli bir adet girin"
$c = $c.Replace("Ge${r}erli bir adet girin", "Geçerli bir adet girin")

# "Geçerli bir tutar girin"
$c = $c.Replace("Ge${r}erli bir tutar girin", "Geçerli bir tutar girin")

# "Ürün depoya eklendi"
$c = $c.Replace("${r}r${r}n depoya eklendi", "Ürün depoya eklendi")

# "Ürün başarıyla eklendi"
$c = $c.Replace("${r}r${r}n ba${r}ar${r}yla eklendi", "Ürün başarıyla eklendi")

# "Ürün ekleme hatası"
$c = $c.Replace("${r}r${r}n ekleme hatas${r}", "Ürün ekleme hatası")

# "Ürün silindi"
$c = $c.Replace("${r}r${r}n silindi", "Ürün silindi")

# "Ürün silme hatası"
$c = $c.Replace("${r}r${r}n silme hatas${r}", "Ürün silme hatası")

# "Satış kaydedildi" (in debugPrint)
$c = $c.Replace("Sat${r}${r} kaydedildi", "Satış kaydedildi")

# "satış kaydedildi" (in snackbar)
$c = $c.Replace("sat${r}${r} kaydedildi", "satış kaydedildi")

# "Satış hatası"
$c = $c.Replace("Sat${r}${r} hatas${r}", "Satış hatası")

# "Ürün depo tablosunu güncelle"
$c = $c.Replace("${r}r${r}n depo tablosunu g${r}ncelle", "Ürün depo tablosunu güncelle")

# === COMMENTS ===
$c = $c.Replace("// SATI${r} ${r}${r}LEM${r}", "// SATIŞ İŞLEMİ")
$c = $c.Replace("// ${r}R${r}N B${r}LG${r}S${r}", "// ÜRÜN BİLGİSİ")
$c = $c.Replace("// ADET B${r}LG${r}LER${r}", "// ADET BİLGİLERİ")
$c = $c.Replace("// SATI${r} ADED${r}", "// SATIŞ ADEDİ")
$c = $c.Replace("// SATI${r} TUTARI", "// SATIŞ TUTARI")
$c = $c.Replace("// A${r}IKLAMA", "// AÇIKLAMA")
$c = $c.Replace("// S${r}L BUTONU", "// SİL BUTONU")
$c = $c.Replace("// ${r}R${r}N EKLE BUTONU", "// ÜRÜN EKLE BUTONU")
$c = $c.Replace("// ${r}R${r}NLER L${r}STES${r}", "// ÜRÜNLER LİSTESİ")
$c = $c.Replace("// BA${r}LIK BANNER", "// BAŞLIK BANNER")
$c = $c.Replace("// MARKA SE${r}${r}M${r}", "// MARKA SEÇİMİ")
$c = $c.Replace("// MODEL SE${r}${r}M${r}", "// MODEL SEÇİMİ")
$c = $c.Replace("// RENK SE${r}${r}M${r}", "// RENK SEÇİMİ")

# === SHORTER PATTERNS ===

# "Satışı Kaydet"
$c = $c.Replace("Sat${r}${r}${r} Kaydet", "Satışı Kaydet")

# "Satış Yap" 
$c = $c.Replace("Sat${r}${r} Yap", "Satış Yap")

# "Satılacak Adet"
$c = $c.Replace("Sat${r}lacak Adet", "Satılacak Adet")

# "Satış Tutarı" (with ?)
$c = $c.Replace("Sat${r}${r} Tutar${r}", "Satış Tutarı")

# "Satılan:" 
$c = $c.Replace("Sat${r}lan:", "Satılan:")

# "Marka Seç"
$c = $c.Replace("Marka Se${r}", "Marka Seç")

# "Renk Seç"
$c = $c.Replace("Renk Se${r}", "Renk Seç")

# "Model Seç"
$c = $c.Replace("Model Se${r}", "Model Seç")

# "Bir marka seç"
$c = $c.Replace("Bir marka se${r}", "Bir marka seç")

# "Model bulunamadı"
$c = $c.Replace("Model bulunamad${r}", "Model bulunamadı")

# "$kaliteTipi Ürün Ekle"
$c = $c.Replace("`$kaliteTipi ${r}r${r}n Ekle", "`$kaliteTipi Ürün Ekle")

# "Örn: Lekeyle geldi"
$c = $c.Replace("${r}rn: Lekeyle geldi", "Örn: Lekeyle geldi")

# "İptal"
$c = $c.Replace("${r}ptal", "İptal")

# "Adet 0'dan büyük olmalı"
$c = $c.Replace("b${r}y${r}k olmal${r}", "büyük olmalı")

# "Model seçin"
$c = $c.Replace("Model se${r}in", "Model seçin")

# "Renk seçin"
$c = $c.Replace("Renk se${r}in", "Renk seçin")

# Standalone "Ürün" (in label)
$c = $c.Replace("'${r}r${r}n'", "'Ürün'")

# "göre" patterns
$c = $c.Replace("g${r}re", "göre")

# "güncelle" patterns
$c = $c.Replace("g${r}ncelle", "güncelle")

# "oluştur"
$c = $c.Replace("olu${r}tur", "oluştur")

# "için"
$c = $c.Replace("i${r}in", "için")

# Any remaining standalone patterns
$c = $c.Replace("se${r}in", "seçin")
$c = $c.Replace("se${r}im", "seçim")

$after = ($c.ToCharArray() | Where-Object { $_ -eq $r }).Count
Write-Host "After: $after replacement chars remaining"

if ($after -gt 0) {
    # Find remaining contexts
    $lines = $c.Split("`n")
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].Contains($r)) {
            Write-Host "Line $($i+1): $($lines[$i].Trim())"
        }
    }
}

# Write back as UTF-8 with BOM
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($filePath, $c, $utf8Bom)
Write-Host "File written successfully!"
