# MODEL MALİYET HESAPLAMA VE RAPOR SİSTEMİ

## 📋 Özet

Model "Tamamlandı" olarak işaretlendiğinde, sistem otomatik olarak:
1. **Maliyetleri hesaplar** - İplik, makina, işleme, genel giderler vb.
2. **Raporlar** - Maliyet raporu `maliyet_hesaplama` tablosuna kaydeder
3. **Entegre eder** - Gelişmiş Raporlar sayfasında gösterilir
4. **Analiz sağlar** - Kar/zarar, kar marjı, karlılık oranları

---

## 🔧 TEKNIK DETAYLAR

### 1. Model Maliyet Servisi
**Dosya**: `lib/services/model_maliyet_hesaplama_servisi.dart`

**Temel Metodlar**:
- `modelTamamlandıMaliyetiHesapla()` - Model tamamlandığında çağrılır
- `_tumMaliyetleriHesapla()` - Tüm maliyetleri hesapla
- `_maliyetiKaydet()` - Veritabanına kaydet
- `getMaliyetRaporu()` - Tek modelin raporunu getir
- `getTumMaliyetRaporlari()` - Tüm modelların raporlarını getir
- `getKarlilikRaporu()` - Karlılık analizi

### 2. Model Detay Sayfası Güncellemeleri
**Dosya**: `lib/model_detay.dart`

**Değişiklikler**:
- Import eklendi: `model_maliyet_hesaplama_servisi.dart`
- `_tamamlamayiKaydet()` fonksiyonu güncellenmiş
- Model tamamlandığında maliyet servisi çağrılıyor

```dart
if (modelTamamlandi) {
  final maliyetServisi = ModelMaliyetHesaplamaSevisi();
  final maliyetBilgisi = await maliyetServisi.modelTamamlandıMaliyetiHesapla(
    modelId: widget.modelId,
    tamamlananAdet: yeniToplamTamamlanan,
  );
}
```

### 3. Maliyet Rapor Widget'ı
**Dosya**: `lib/widgets/model_maliyet_rapor_widget.dart`

**Özellikler**:
- Finansal özet kartları (Maliyet, Satış, Kar, Oran)
- Detaylı maliyet breakdown
- Ekspandable kartlar
- Tarih formatı ve para formatı

### 4. Gelişmiş Raporlar Entegrasyonu
**Dosya**: `lib/advanced_reports_page.dart`

**Güncellemeler**:
- `model_cost` rapor tipi eklendi
- `ModelMaliyetRaporWidget` import edildi
- Case statement'e `model_cost` handler eklendi

---

## 💰 HESAPLANAN MALIYET BİLGİLERİ

### Maliyet Kalemleri
```
1. İplik Maliyeti         = İplik Kg Fiyatı × Kullanılan Kg
2. Makina Maliyeti        = Makina Çıkış Süresi × Dk Fiyatı
3. Konfeksiyon Maliyeti   = Birim Fiyatı
4. Naksş Maliyeti         = Birim Fiyatı
5. Yıkama Maliyeti        = Birim Fiyatı
6. Ütü Maliyeti           = Birim Fiyatı
7. İlik-Düğme Maliyeti    = Birim Fiyatı
8. Paketleme Maliyeti     = Birim Fiyatı
9. Genel Giderler         = Toplam × %8
```

### Hesaplanacak Veriler
```
- Birim Maliyet           = Tüm maliyetlerin toplamı
- Toplam Maliyet          = Birim Maliyet × Tamamlanan Adet
- Kar Marjı               = %20 (sabit)
- Birim Satış Noktası     = Birim Maliyet × (1 + Kar Marjı)
- Toplam Satış Geliri     = Birim Satış Noktası × Tamamlanan Adet
- Kar/Zarar               = Toplam Satış Geliri - Toplam Maliyet
```

---

## 📊 RAPOR SAYFASI

### Görüntülenen Bilgiler

#### Finansal Özet (Toplam)
- **Toplam Maliyet** - Tüm modellerin toplam maliyeti
- **Toplam Satış Geliri** - Tüm modellerin satış değeri
- **Toplam Kar/Zarar** - Toplam kâr veya zarar
- **Kar Oranı** - Kar/Satış × 100 (%)

#### Model Maliyetleri (Detay)
Her model için:
- Tamamlanan adet
- Tarih
- Maliyet detayları (İplik, Makina, Konfeksiyon vb.)
- Birim maliyeti
- Birim satış noktası
- Kar marjı
- Toplam maliyet
- Toplam satış geliri
- Kar/zarar tutarı

---

## 🔄 VERİ AKIŞI

```
Model Tamamlandı
        ↓
_tamamlamayiKaydet() çağrılıyor
        ↓
Model Tamamlandi = true
        ↓
ModelMaliyetHesaplamaSevisi.modelTamamlandıMaliyetiHesapla()
        ↓
Tüm maliyetler hesaplanıyor
        ↓
maliyet_hesaplama tablosuna kaydediliyor
        ↓
Gelişmiş Raporlar → Model Maliyetleri
        ↓
ModelMaliyetRaporWidget gösteriliy
        ↓
Finansal analiz ve kar/zarar görüntüleniyor
```

---

## 📱 KULLANILAN TEKNOLOJİLER

- **Supabase** - Veritabanı (PostgreSQL)
- **Flutter** - UI/Frontend
- **Dart** - Dil
- **maliyet_hesaplama** - Tablo
- **triko_takip** - Model tablosu

---

## 🧪 TEST

### Test Adımları

1. **Model açın** ve "Tamamla" butonuna basın
2. **Adet girin** ve kaydedin
3. **Model tamamlandığında** maliyet hesaplaması otomatik yapılır
4. **Gelişmiş Raporlar**'a gidip "Model Maliyetleri" sekmesini seçin
5. **Finansal özet ve detayları** görün

### Test Verileri

Model'de minimum şunlar olmalı:
- `iplik_kg_fiyati` - İplik fiyatı
- `iplik_maliyeti` - İplik maliyeti
- `makina_cikis_suresi` - Makina çıkış süresi
- `makina_dk_fiyati` - Makina dakika fiyatı

---

## ⚙️ KONFIGÜRASYON

### Kar Marjı
Dosya: `lib/services/model_maliyet_hesaplama_servisi.dart`

Satır ~156:
```dart
maliyet['kar_marji_yuzde'] = 20.0;  // %20 (değiştirilebilir)
```

### Genel Giderler
Dosya: `lib/services/model_maliyet_hesaplama_servisi.dart`

Satır ~149:
```dart
maliyet['genel_giderler'] = altMaliyetToplami * 0.08; // %8 (değiştirilebilir)
```

---

## 🐛 SORUN GIDERME

### Maliyet hesaplanmıyor
✅ **Çözüm**: Model'de `iplik_maliyeti` ve `makina_dk_fiyati` alanlarının dolu olduğunu kontrol edin

### Rapor sayfasında gösterilmiyor
✅ **Çözüm**: "Gelişmiş Raporlar" → "Model Maliyetleri" sekmesini seçin

### Sıfır maliyet gösteriyor
✅ **Çözüm**: Model'deki maliyet alanlarının numeric olduğundan emin olun

---

## 📈 GELECEK GELİŞTİRMELER

- [ ] Maliyet tahmini (tahmin maliyeti vs gerçek maliyet karşılaştırması)
- [ ] Trend analizi (aylık kar/zarar)
- [ ] Müşteri karlılığı (müşteri bazında kar/zarar)
- [ ] Ürün karlılığı (ürün tipi bazında kar/zarar)
- [ ] Büdge analizi (planlanan vs gerçekleşen)

---

**Son Güncelleme**: 3 Ocak 2026
**Versiyon**: 1.0
