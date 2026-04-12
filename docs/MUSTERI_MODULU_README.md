# Müşteri Kartları (CRM) Modülü

Bu modül, mevcut üretim takip sistemine **müşteri yönetimi (CRM)** özelliği ekler. Sistem bozulmadan entegre edilecek şekilde tasarlanmıştır.

## 📋 Özellikler

### Müşteri Yönetimi
- ✅ **Bireysel ve Kurumsal Müşteri Desteği**
  - Bireysel: Ad, soyad, telefon, email
  - Kurumsal: Şirket adı, yetkili kişi, vergi bilgileri
- ✅ **Detaylı İletişim Bilgileri**
  - Telefon, email, adres bilgileri
  - İl, ilçe, posta kodu desteği
- ✅ **Durum Yönetimi**: Aktif, Pasif, Askıda
- ✅ **Mali Bilgiler**: Kredi limiti, bakiye takibi
- ✅ **Notlar ve Açıklamalar**

### Arama ve Filtreleme
- ✅ **Gelişmiş Arama**: Ad, soyad, şirket, telefon ile arama
- ✅ **Müşteri Tipi Filtresi**: Bireysel/Kurumsal
- ✅ **Durum Filtresi**: Aktif/Pasif/Askıda
- ✅ **Sayfalama**: Büyük veri setleri için performanslı listeleme

### Güvenlik
- ✅ **Veri Doğrulama**: Telefon, email, vergi numarası kontrolü
- ✅ **Tekrar Kontrolü**: Aynı telefon/email/vergi no ile çoklu kayıt önlenir
- ✅ **Supabase RLS**: Rol tabanlı erişim kontrolü

## 🛠️ Kurulum

### 1. Supabase Veritabanı Kurulumu

```sql
-- supabase_musteri_schema.sql dosyasını Supabase SQL Editor'de çalıştırın
-- Bu dosya mevcut sistemi bozmadan yeni tabloları oluşturur
```

### 2. Flutter Dosyaları
Aşağıdaki dosyalar projeye eklenmiştir:

```
lib/
├── musteri_model.dart              # Müşteri veri modeli
├── musteri_listesi_page.dart       # Müşteri listesi sayfası
├── musteri_ekle_page.dart          # Müşteri ekleme/düzenleme sayfası  
├── musteri_detay_page.dart         # Müşteri detay sayfası
└── services/
    └── musteri_service.dart        # Müşteri veritabanı işlemleri
```

### 3. Ana Sayfa Entegrasyonu
Ana sayfa (`ana_sayfa.dart`) güncellenmiş ve "Müşteri Kartları" butonu eklenmiştir.

## 📱 Kullanım

### Müşteri Ekleme
1. Ana sayfadan "Müşteri Kartları" butonuna tıklayın
2. Sağ altta "+" butonuna tıklayın
3. Müşteri tipini seçin (Bireysel/Kurumsal)
4. Gerekli bilgileri doldurun
5. "KAYDET" butonuna tıklayın

### Müşteri Arama ve Filtreleme
- **Arama kutusu**: Ad, soyad, şirket veya telefon ile arama
- **Müşteri Tipi**: Bireysel, Kurumsal veya Tümü
- **Durum**: Aktif, Pasif, Askıda veya Tümü
- **Temizle**: Tüm filtreleri sıfırlar

### Müşteri İşlemleri
- **Detay Görüntüle**: Müşteri kartına tıklayın
- **Düzenle**: ⋮ menüsünden "Düzenle" seçin
- **Durum Değiştir**: ⋮ menüsünden "Durum Değiştir" seçin
- **Sil**: ⋮ menüsünden "Sil" seçin (sadece admin)

## 🔗 Entegrasyon Noktaları

### Mevcut Sistemle Entegrasyon
Bu modül gelecekte şu alanlarda entegre edilecek:

1. **Sipariş Sistemi**: Müşteri seçimi için dropdown
2. **Faturalandırma**: Müşteri bilgileri otomatik dolduruluması  
3. **Raporlama**: Müşteri bazlı satış raporları
4. **Üretim Takibi**: Siparişlerde müşteri bilgisi gösterimi

### API Entegrasyonu
```dart
// Müşteri seçici widget örneği
Widget buildMusteriSecici() {
  return FutureBuilder<List<MusteriModel>>(
    future: MusteriService.tumMusterileriGetir(durum: 'aktif'),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return DropdownButton<int>(
          items: snapshot.data!.map((musteri) => 
            DropdownMenuItem(
              value: musteri.id,
              child: Text(musteri.tamAd),
            )
          ).toList(),
          onChanged: (musteriId) {
            // Müşteri seçildi
          },
        );
      }
      return CircularProgressIndicator();
    },
  );
}
```

## 📊 Veri Yapısı

### Musteriler Tablosu
```sql
CREATE TABLE musteriler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100),
    sirket VARCHAR(255),
    telefon VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    adres TEXT,
    il VARCHAR(50),
    ilce VARCHAR(50),
    posta_kodu VARCHAR(10),
    vergi_no VARCHAR(20) UNIQUE,
    vergi_dairesi VARCHAR(100),
    musteri_tipi VARCHAR(20) DEFAULT 'bireysel',
    durum VARCHAR(20) DEFAULT 'aktif',
    notlar TEXT,
    kredi_limiti DECIMAL(15,2),
    bakiye DECIMAL(15,2) DEFAULT 0,
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🚀 Gelecek Geliştirmeler

### Kısa Vadeli (1-2 hafta)
- [ ] Sipariş modülüne müşteri seçici ekleme
- [ ] Müşteri detay sayfasında sipariş geçmişi
- [ ] Müşteri bazlı raporlar

### Orta Vadeli (1-2 ay)
- [ ] Müşteri iletişim geçmişi modülü
- [ ] Çoklu adres desteği
- [ ] Müşteri segmentasyonu

### Uzun Vadeli (3-6 ay)
- [ ] CRM dashboard'u
- [ ] Email entegrasyonu
- [ ] Müşteri analitikleri
- [ ] Satış fırsatları takibi

## 🛡️ Güvenlik

### Veri Koruması
- Telefon numaraları unique constraint ile korunur
- Email adresleri tekrar kullanılamaz
- Vergi numaraları benzersizlik kontrolü

### Rol Tabanlı Erişim
- **Admin**: Tüm işlemler (ekleme, düzenleme, silme)
- **User**: Müşteri ekleme ve düzenleme
- **Personel**: Sadece görüntüleme
- **Depocu**: Sadece görüntüleme

## 📞 Destek

Bu modül hakkında sorularınız için:
- Kod incelemeleri için: `musteri_service.dart` dosyasını kontrol edin
- Veri yapısı için: `supabase_musteri_schema.sql` dosyasını inceleyin
- UI/UX için: `musteri_listesi_page.dart` dosyasını inceleyin

## 📝 Changelog

### v1.0.0 (İlk Sürüm)
- ✅ Temel müşteri CRUD işlemleri
- ✅ Bireysel/Kurumsal müşteri desteği
- ✅ Arama ve filtreleme
- ✅ Sayfalama sistemi
- ✅ Supabase entegrasyonu
- ✅ Ana sayfa entegrasyonu
