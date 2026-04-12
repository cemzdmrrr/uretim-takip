# Üretim Aşamaları Sistemi Kurulum Kılavuzu

## 🎯 Genel Bakış

Bu sistem, tekstil üretim sürecinin tüm aşamalarını yönetmek için geliştirilmiştir. Her üretim aşaması için ayrı rol tabanlı dashboard'lar ve atama sistemi bulunmaktadır.

## 📋 Üretim Aşamaları

1. **Dokuma** - Kumaş dokuma işlemleri
2. **Konfeksiyon** - Kesim ve dikim işlemleri  
3. **Yıkama** - Ürün yıkama işlemleri
4. **Ütü** - Ütüleme ve pres işlemleri
5. **İlik Düğme** - İlik açma ve düğme dikme işlemleri
6. **Kalite Kontrol** - Ürün kalite kontrol işlemleri
7. **Paketleme** - Ürün paketleme işlemleri

## 🔧 Veritabanı Kurulumu

### 1. Adım: Temel Tabloları Oluşturun

Supabase Dashboard'da sırasıyla şu SQL dosyalarını çalıştırın:

```sql
-- 1. Önce temel üretim aşamaları tablolarını oluşturun
-- Dosya: uretim_asamalari_schema.sql
```

### 2. Adım: Rolleri Güncelleyin

```sql
-- 2. Yeni rolleri user_roles constraint'ine ekleyin
-- Dosya: yeni_roller_ekle.sql
```

### 3. Adım: RLS Politikalarını Ekleyin

```sql
-- 3. Güvenlik politikalarını ekleyin
-- Dosya: uretim_asamalari_rls_politikalari.sql
```

### 4. Adım: Mevcut Verileri Güncelleyin

```sql
-- 4. Mevcut models tablosuna yeni durumları ekleyin
-- models_dokuma_durumu_kolonu.sql dosyası zaten çalıştırılmış olmalı
```

## 👥 Rol Sistemi

### Yeni Roller:
- `dokuma` - Dokuma personeli
- `konfeksiyon` - Konfeksiyon personeli
- `yikama` - Yıkama personeli
- `utu` - Ütü personeli
- `ilik_dugme` - İlik düğme personeli
- `kalite_kontrol` - Kalite kontrol personeli
- `paketleme` - Paketleme personeli

### Mevcut Yönetici Rolleri:
- `admin` - Sistem yöneticisi
- `ik` - İnsan kaynakları
- `user` - Genel kullanıcı
- `personel` - Personel detay görünümü

## 🎮 Kullanım Senaryosu

### Admin/Yönetici Perspektifi:

1. **Model Listesi**'nden modelleri seçer
2. **Toplu İşlemler** menüsünden ilgili üretim aşaması seçer:
   - "Dokuma Personeline Ata"
   - "Konfeksiyon Personeline Ata"
   - "Yıkama Personeline Ata"
   - vb.
3. Personel seçer ve notlar ekler
4. Atama tamamlanır

### Üretim Personeli Perspektifi:

1. **Giriş yapar** → Otomatik olarak kendi dashboard'unu görür
2. **4 Tab Yapısı**:
   - **Bekleyen**: Onay bekleyen işler
   - **Onaylanan**: Onaylanmış, başlanabilir işler
   - **İşlemde**: Şu anda yapılan işler
   - **Tümü**: Tüm atanmış işler

3. **İş Akışı**:
   - Model kartına tıklar → Detay görür
   - **Onaylar/Reddeder** (bekleyen işler için)
   - **İşleme Başlar** (onaylanan işler için)
   - **Tamamlar** (işlemde olan işler için)

## 🌟 Özellikler

### ✅ Genel Sistem Özellikleri:
- **Role-based Access Control** - Her rol sadece kendi işlerini görür
- **Responsive Tasarım** - Mobil ve masaüstü uyumlu
- **Real-time Güncellemeler** - Anlık veritabanı senkronizasyonu
- **Comprehensive Error Handling** - Kapsamlı hata yönetimi
- **Tab-based Organizasyon** - Kolay navigasyon
- **Status Tracking** - Durum takip sistemi
- **Note Sistemi** - İş notları ekleme

### ✅ Dashboard Özellikleri:
- **4 Tab Yapısı**: Bekleyen, Onaylanan, İşlemde, Tümü
- **Model Kartları**: Detaylı bilgi görüntüleme
- **Durum Badge'leri**: Görsel durum göstergeleri
- **Tarih Takibi**: Atama, onay, başlama, tamamlama tarihleri
- **Pull-to-Refresh**: Aşağı çekerek yenileme

### ✅ Atama Sistemi:
- **Toplu Atama**: Birden fazla model seçerek atama
- **Personel Seçimi**: Dropdown ile personel seçimi
- **Not Ekleme**: Atama notları
- **Durum Güncellemesi**: Otomatik model durumu güncelleme

## 🔒 Güvenlik

- **RLS (Row Level Security)**: Her kullanıcı sadece kendi verilerine erişir
- **Role-based Access**: Rol tabanlı sayfa erişimi
- **Secure Authentication**: Supabase Auth entegrasyonu
- **Database Constraints**: Veri bütünlüğü kontrolü

## 📱 Kullanıcı Deneyimi

### Responsive Tasarım:
- **Mobil**: Tek sütun layout, touch-friendly
- **Tablet**: Adaptif grid layout
- **Desktop**: Çoklu sütun, geniş görünüm

### Kullanım Kolaylığı:
- **Sezgisel Navigasyon**: Tab-based struktur
- **Görsel Durum Göstergeleri**: Renkli badge'ler
- **Hızlı İşlemler**: Tek tıkla onay/red/başlama
- **Anlık Geri Bildirim**: Toast mesajları

## 📊 Raporlama

Sistem şu verileri takip eder:
- **Atama Tarihleri**: Ne zaman atandı
- **Onay Durumları**: Onaylandı/Reddedildi
- **İşlem Süreleri**: Başlama-Tamamlama süreleri
- **Personel Performansı**: İş tamamlama oranları
- **Red Sebepleri**: Kalite geri bildirimleri

## 🚀 Genişletme İmkanları

Sistem modüler yapısı sayesinde kolayca genişletilebilir:
- **Yeni Üretim Aşamaları**: Kolayca eklenebilir
- **Özel Detay Sayfaları**: Aşamaya özel formlar
- **Rapor Modülleri**: Özel raporlama ekranları
- **Entegrasyonlar**: Üçüncü parti sistem bağlantıları

## 📞 Destek

Sistem kurulumu veya kullanımı hakkında sorularınız için dokümantasyonu inceleyin veya teknik destek ile iletişime geçin.

---

**Not**: Bu sistem production ortamında kullanımdan önce test ortamında kapsamlı şekilde test edilmelidir.
