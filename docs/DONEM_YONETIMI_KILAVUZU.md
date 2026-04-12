# Dönem Bazlı Personel İşlemleri Kılavuzu

## 📋 Dönem Yönetimi Sistemi

Bu sistem, personel işlemlerinin dönemsel olarak takip edilmesini sağlar.

### 🎯 Özellikler

1. **Dönem Tanımlama**: Yıllık, üç aylık veya özel dönemler oluşturabilirsiniz
2. **Aktif Dönem**: Sadece bir dönem aktif olabilir
3. **Dönemsel Filtreleme**: Tüm raporlar dönem bazlı filtrelenebilir
4. **Otomatik Kayıt**: Yeni işlemler aktif döneme otomatik atanır

### 🚀 Kurulum Adımları

1. **Supabase Tablolarını Oluşturun**:
   ```sql
   -- supabase_donem_schema.sql dosyasındaki kodları çalıştırın
   ```

2. **Dönem Tanımlamaları**:
   - Personel Anasayfa → Dönem Yönetimi
   - "Yeni Dönem Ekle" butonu ile dönem oluşturun
   - Dönem kodları: 2025-1, 2025-Q1, 2025-H1 gibi

3. **Aktif Dönem Ayarı**:
   - Dönem listesinde "Aktif Yap" butonu
   - Sadece bir dönem aktif olabilir
   - Yeni işlemler aktif döneme kaydedilir

### 📊 Dönemsel Takip

#### Dashboard'da Dönem Seçimi
- Ana sayfada dönem seçici ile filtreleme
- Seçilen döneme ait veriler gösterilir
- "Tüm Dönemler" seçeneği ile genel görünüm

#### Bordro Yönetiminde Dönem
- Bordro sayfasında dönem seçici
- Seçilen dönemde bordro kayıtları
- PDF çıktılarında dönem bilgisi

#### İzin ve Mesai Takibi
- Her izin/mesai kaydı döneme bağlı
- Dönemsel izin kotaları
- Dönemsel mesai raporları

### 🎭 Örnek Dönem Yapıları

**Üç Aylık Dönemler**:
- 2025-Q1 (Ocak-Mart)
- 2025-Q2 (Nisan-Haziran)
- 2025-Q3 (Temmuz-Eylül)
- 2025-Q4 (Ekim-Aralık)

**Altı Aylık Dönemler**:
- 2025-H1 (Ocak-Haziran)
- 2025-H2 (Temmuz-Aralık)

**Yıllık Dönemler**:
- 2024 (Tüm yıl)
- 2025 (Tüm yıl)

### 🔧 Gelişmiş Özellikler

#### Dönem Geçişi
```dart
// Programatik dönem değiştirme
await DonemHelper.setAktifDonem('2025-Q2');
```

#### Dönem Filtreleme
```dart
// Belirli dönem verisi çekme
final bordroData = await client
    .from('bordro')
    .select()
    .eq('donem', '2025-Q1');
```

#### Toplu Dönem Atama
```dart
// Mevcut kayıtları döneme atama
await client
    .from('bordro')
    .update({'donem': '2025-Q1'})
    .isNull('donem');
```

### 🎯 Kullanım Senaryoları

1. **Yeni Şirket**: İlk dönem oluşturup aktif yapın
2. **Dönem Sonu**: Yeni dönem oluşturup geçiş yapın
3. **Raporlama**: Geçmiş dönemleri seçerek karşılaştırma
4. **Denetim**: Dönem bazlı kayıt kontrolü

### ⚠️ Dikkat Edilecekler

- Dönem kodları benzersiz olmalı
- Aktif dönem değiştirilmeden önce mevcut işlemler tamamlanmalı
- Geçmiş dönem verilerinin değiştirilmemesine dikkat edin
- Düzenli yedekleme yapın

### 🔄 Dönem Yönetimi İş Akışı

1. **Dönem Başı**: Yeni dönem oluştur ve aktif yap
2. **Dönem İçi**: Normal işlemler (bordro, izin, mesai)
3. **Dönem Sonu**: Raporları al, dönemi kapat
4. **Yeni Dönem**: Bir sonraki dönemi aktif yap

Bu sistem sayesinde personel işlemlerinizi dönemsel olarak takip edebilir, geçmiş verilerle karşılaştırma yapabilir ve düzenli raporlama süreçlerinizi otomatikleştirebilirsiniz.
