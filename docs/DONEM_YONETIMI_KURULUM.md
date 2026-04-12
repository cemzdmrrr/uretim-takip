# 🔧 Dönem Yönetimi Kurulum Talimatları

## ⚠️ ÖNEMLİ ADIMLAR

### 1️⃣ Veritabanı Şemasını Yükleyin

1. **Supabase Dashboard**'a gidin: https://app.supabase.com
2. Projenizi seçin
3. Sol menüden **"SQL Editor"** seçin
4. **"New query"** butonuna tıklayın
5. `SUPABASE_SCHEMA_INSTALL.sql` dosyasının içeriğini kopyalayın
6. SQL Editor'a yapıştırın
7. **"Run"** butonuna tıklayın

### 2️⃣ Kurulumu Doğrulayın

SQL çalıştıktan sonra şu kontrolleri yapın:

```sql
-- Tabloların oluştuğunu kontrol edin
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('donemler', 'personel_donem');

-- Örnek verileri kontrol edin
SELECT * FROM donemler;
```

### 3️⃣ Uygulamayı Güncelle

Veritabanı kurulumu tamamlandıktan sonra:

1. `personel_anasayfa.dart` dosyasında **38. satırda** bulunan:
   ```dart
   if (kullaniciRolu == 'admin' && false) // false ekleyerek geçici olarak kapatıldı
   ```
   
2. **`false`** kısmını **`true`** olarak değiştirin:
   ```dart
   if (kullaniciRolu == 'admin' && true) // Yeni dönem özelliği aktif
   ```

### 4️⃣ Test Edin

1. Uygulamayı yeniden başlatın
2. Admin kullanıcısı ile giriş yapın
3. Dashboard'da **"Yeni Dönem"** butonu görünmeli
4. Dönem seçici dropdown çalışmalı

## 🚨 Sorun Giderme

### Hata: "column donemler.yil does not exist"
- SQL şeması henüz çalıştırılmamış
- Yukarıdaki adımları tekrar takip edin

### Hata: "permission denied"
- RLS politikaları doğru kurulmamış
- SQL dosyasını tekrar çalıştırın

### Dönem seçici boş görünüyor
- Örnek veriler eklenmemiş
- SQL'deki INSERT komutlarını kontrol edin

## 📋 Özellikler

✅ **Yeni Dönem Ekleme** (Sadece Admin)
✅ **Dönem Seçimi** (Tüm Kullanıcılar)  
✅ **Otomatik Personel Kayıt Oluşturma**
✅ **Veri Korunması** (Eski veriler silinmez)
✅ **Rol Tabanlı Güvenlik**

## 🔄 Güncellemeler

Bu sistem eklendiğinde:
- Mevcut verileriniz korunur
- Eski dönem sistemi devre dışı kalır
- Yeni sistem devreye girer

---
**Not**: Bu işlemler veritabanında değişiklik yapar. Yedek almanızı öneririz.
