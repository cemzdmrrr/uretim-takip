# FİRE YÖNETİMİ KURULUM TALİMATI

## ⚠️ ÖNEMLİ: Önce SQL Fonksiyonlarını Yükleyin!

Sistem çalışması için önce Supabase'e SQL fonksiyonlarını yüklemeniz gerekiyor.

## 1. SQL Fonksiyonlarını Yükle

### Adım 1: Supabase Dashboard'a Git
1. https://supabase.com adresine git
2. Projenizi seçin
3. Sol menüden **SQL Editor** sekmesine tıkla

### Adım 2: SQL Kodunu Kopyala
`asama_adet_aktarimi.sql` dosyasının **TAMAMINI** kopyala

### Adım 3: SQL Editor'e Yapıştır ve Çalıştır
1. "New query" butonuna tıkla
2. Kopyaladığın kodu yapıştır
3. **RUN** butonuna tıkla (veya Ctrl+Enter)

### Adım 4: Kontrol Et
Aşağıdaki sorguyu çalıştırarak fonksiyonların oluşturulduğunu kontrol et:

```sql
SELECT 
    proname as fonksiyon_adi,
    prosrc as aciklama
FROM pg_proc 
WHERE proname LIKE '%asama%' OR proname LIKE '%gerceklesen%';
```

Beklenen sonuç:
- `get_onceki_asama_gerceklesen_adetler`
- `update_sonraki_asama_hedef_adetler`

## 2. Flutter/Dart Güncellemeleri Yapıldı ✅

Aşağıdaki dosyalar otomatik güncellendi:

### ✅ `lib/services/beden_service.dart`
Yeni fonksiyonlar eklendi:
- `getOncekiAsamaGerceklesenAdetler()`
- `updateSonrakiAsamaHedefAdetler()`
- `hedefAdetleriOncekiAsamadanAl()`

### ✅ `lib/dialogs/beden_uretim_dialog.dart`
- Konfeksiyon ve sonraki aşamalarda otomatik olarak önceki aşamadan gelen adetleri alır
- Fire düşülmüş adetler hedef olarak gösterilir

### ✅ `lib/kalite_kontrol_panel.dart`
- Model toplam adeti artık beden dağılımından hesaplanır
- Boş gösterme sorunu çözüldü

## 3. Sistem Nasıl Çalışır?

### Senaryo: Dokumada Fire Verildi

```
DOKUMA AŞAMASI:
Başlangıç:  S:200, M:200, L:200, XL:200  (Toplam: 800)
Üretilen:   S:200, M:200, L:200, XL:200
Fire:       S:50,  M:0,   L:0,   XL:0
Kalan:      S:150, M:200, L:200, XL:200  (Toplam: 750) ✅
```

### Konfeksiyona Otomatik Aktarım

Dialog açıldığında:

```dart
// ÖNCEDEN (HATALI):
Hedef: S:200, M:200, L:200, XL:200  ❌

// ŞIMDI (DOĞRU):
Hedef: S:150, M:200, L:200, XL:200  ✅
```

## 4. Test Etme

### Test 1: Dokumada Fire Ver

1. Dokuma panelinde bir model seç
2. "Üretim Gir" butonuna tıkla
3. S beden için:
   - Üretilen: 200
   - Fire: 50
4. Kaydet

### Test 2: Konfeksiyonda Kontrol Et

1. Aynı modeli Konfeksiyon panelinde seç
2. "Üretim Gir" butonuna tıkla
3. **Hedef adetleri kontrol et:**
   - S: 150 olmalı (200-50) ✅
   - M: 200 olmalı
   - L: 200 olmalı
   - XL: 200 olmalı

### Test 3: Kalite Kontrol Paneli

1. Kalite Kontrol paneline git
2. Model kartında "Model Toplam Adet" alanını kontrol et
3. Artık boş değil, gerçek adetleri göstermeli ✅

## 5. Sorun Giderme

### Sorun: "Function does not exist" Hatası

**Çözüm:**
1. SQL Editor'de `asama_adet_aktarimi.sql` dosyasını tekrar çalıştır
2. Fonksiyonların oluşturulduğunu kontrol et (Adım 4)

### Sorun: Konfeksiyonda Hala Eski Adetler Görünüyor

**Çözüm:**
1. Uygulamayı yeniden başlat (Hot Restart)
2. Veritabanında `konfeksiyon_beden_takip` tablosunu kontrol et:

```sql
SELECT * FROM konfeksiyon_beden_takip 
WHERE model_id = 'model-uuid-buraya';
```

### Sorun: Kalite Kontrol'de Hala Boş Görünüyor

**Çözüm:**
1. Model'in beden dağılımı var mı kontrol et:

```sql
SELECT * FROM model_beden_dagilimi 
WHERE model_id = 'model-uuid-buraya';
```

2. Yoksa, model ekle/düzenle ekranından beden dağılımını kaydet

## 6. Önemli Notlar

⚠️ **Fire Yönetimi Otomatik Çalışıyor**
- Dokuma tamamlandığında Konfeksiyona adetler otomatik aktarılmıyor
- Her aşamada "Üretim Gir" dialogu açıldığında otomatik hesaplanıyor

⚠️ **Manuel Aktarım Gerekiyorsa**
Eğer otomatik aktarım istiyorsanız, dokuma tamamlama koduna şunu ekleyin:

```dart
// Dokuma tamamlandığında
await _bedenService.updateSonrakiAsamaHedefAdetler(
  modelId: modelId,
  tamamlananAsama: 'dokuma',
  sonrakiAtamaId: konfeksiyonAtamaId,
);
```

## 7. Güncelleme Özeti

### Düzeltilen Sorunlar:

✅ **Sorun 1: Kalite Kontrol'de model toplam adet boş**
- Çözüm: `_getModelToplamAdet()` fonksiyonu eklendi
- Beden dağılımından hesaplıyor

✅ **Sorun 2: Konfeksiyonda fire düşülmemiş adetler görünüyor**
- Çözüm: `_loadData()` fonksiyonunda önceki aşamadan adetleri çekiyor
- S:200 yerine S:150 (fire düşülmüş) gösteriyor

### Yeni Özellikler:

🎯 Aşama arası otomatik adet aktarımı
🎯 Fire yönetimi sistemi
🎯 Gerçekçi üretim takibi

## 8. Sonraki Güncellemeler (Opsiyonel)

Daha da gelişmiş özellikler için:

1. **Üretim Tamamlama Bildirimi**: Bir aşama tamamlandığında sonraki aşamaya bildirim
2. **Fire Analiz Raporu**: Hangi aşamada ne kadar fire verildi
3. **Otomatik Atama Oluşturma**: Bir aşama tamamlanınca sonraki aşamaya otomatik atama

Bunlar için destek isterseniz bildirin! 🚀
