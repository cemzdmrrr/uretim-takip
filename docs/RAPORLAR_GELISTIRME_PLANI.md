# RAPORLAR SAYFASI GELİŞTİRME PLANI

## 1. VERİ KAYNAKLARI ANALİZİ

### Mevcut Veri Tabloları:
- **models**: Model bilgileri ve sipariş detayları
- **uretim_kayitlari**: Üretim aşamaları ve zaman takibi
- **stok_hareketleri**: Stok giriş/çıkış işlemleri
- **kasa_banka_hareketleri**: Mali raporlar için
- **musteriler**: Müşteri bazlı analizler için

### Rapor Kategorileri:
1. **Üretim Raporları**
   - Aşama bazlı süre analizleri
   - Verimlilik raporları
   - Gecikme analizleri

2. **Sipariş Raporları** 
   - Tamamlanan siparişler
   - Bekleyen siparişler
   - Müşteri bazlı analizler

3. **Stok Raporları**
   - Stok seviyeleri
   - Hareket analizleri
   - Kritik stok uyarıları

4. **Mali Raporları**
   - Gelir analizleri
   - Maliyet raporları
   - Karlılık analizleri

## 2. TEKNİK MİMARİ

### Rapor Servisleri:
- `UretimRaporServisi`: Üretim aşaması analizleri
- `SiparisRaporServisi`: Sipariş durumu raporları  
- `StokRaporServisi`: Stok seviye ve hareket raporları
- `MaliRaporServisi`: Finansal analizler

### Grafik Bileşenleri:
- **Zaman Serisi Grafikleri**: Üretim trendi, satış trendi
- **Pasta Grafikleri**: Sipariş durumu dağılımı
- **Bar Grafikleri**: Aşama süreleri, stok seviyeleri
- **Tablo Raporları**: Detaylı listeler ve özetler

## 3. UYGULAMA PLANI

### Faz 1: Temel Rapor Altyapısı (1-2 gün)
- Rapor servis sınıfları oluşturma
- Veri çekme fonksiyonları
- Temel grafik bileşenleri

### Faz 2: Üretim Raporları (1-2 gün)
- Aşama bazlı süre analizleri
- Verimlilik metrikleri
- Gecikme raporları

### Faz 3: Sipariş ve Stok Raporları (1-2 gün)
- Sipariş durum analizleri
- Stok seviye raporları
- Kritik stok uyarıları

### Faz 4: Mali Raporlar ve Gelişmiş Özellikler (1-2 gün)
- Gelir/gider analizleri
- Excel export özellikleri
- Filtre ve arama özellikleri

## 4. DETAYLI ÖZELLİKLER

### Filtreleme Seçenekleri:
- Tarih aralığı
- Model/müşteri seçimi
- Durum filtreleri
- Aşama bazlı filtreleme

### Export Özellikleri:
- PDF rapor oluşturma
- Excel export
- Grafik export
- Email gönderimi

### Dashboard Widgets:
- KPI kartları
- Trend göstergeleri
- Uyarı bildirimleri
- Hızlı özet tabloları
