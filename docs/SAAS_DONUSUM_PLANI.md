# TexPilot SaaS Dönüşüm Planı
## Tek Firma Triko ERP → Çoklu Firma, Çoklu Modül Tekstil SaaS Platformu

---

## 📋 MEVCUT DURUM ANALİZİ

### Mevcut Yapı
- **Tek firma**, tek Supabase projesi, tüm veriler ortak
- **Triko üretimi** odaklı 10 aşamalı üretim hattı (Dokuma → Sevkiyat)
- **RLS kapalı** — yetki kontrolleri sadece Flutter tarafında
- **Rol tabanlı yönlendirme** — admin, kullanıcı, tedarikçi türüne göre dashboard
- **firma_kullanicilari** tablosu var ama kullanılmıyor
- **50+ veritabanı tablosu**, 24 servis, 11 modül, 190+ Dart dosyası
- **Tenant izolasyonu YOK** — tüm sorgular global veri çeker

### Dönüşüm Hedefi
- Çoklu firma (multi-tenant) SaaS platformu
- Her firma kendi tekstil üretim dalını seçer (triko, dokuma, konfeksiyon, vb.)
- Modüler yapı — firma ihtiyacına göre modül ekleme/çıkarma
- Aylık abonelik tabanlı ücretlendirme
- Platform: Web, Windows, mobil (iOS/Android)

---

## 🏗️ ANA DÖNÜŞÜM MİMARİSİ

```
┌─────────────────────────────────────────────────────┐
│                    TexPilot SaaS                     │
├─────────────────────────────────────────────────────┤
│  Platform Katmanı (Auth, Tenant, Abonelik)          │
│  ┌──────────┐ ┌───────────┐ ┌──────────────────┐   │
│  │ Auth &   │ │ Tenant    │ │ Abonelik &       │   │
│  │ Kayıt    │ │ Yönetimi  │ │ Ücretlendirme    │   │
│  └──────────┘ └───────────┘ └──────────────────┘   │
├─────────────────────────────────────────────────────┤
│  Modül Katmanı (Firma seçimine göre aktif)          │
│  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Üretim │ │ Finans  │ │ İK &     │ │ Stok &   │ │
│  │ Modülü │ │ Modülü  │ │ Personel │ │ Depo     │ │
│  └────────┘ └─────────┘ └──────────┘ └──────────┘ │
│  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │Sevkiyat│ │Tedarikçi│ │ Rapor &  │ │ Müşteri  │ │
│  │ Modülü │ │ Modülü  │ │ Analiz   │ │ Modülü   │ │
│  └────────┘ └─────────┘ └──────────┘ └──────────┘ │
├─────────────────────────────────────────────────────┤
│  Üretim Alt-Modülleri (Tekstil Dalına Göre)         │
│  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Triko  │ │ Dokuma  │ │Konfeksi- │ │ Örme     │ │
│  │Üretim  │ │ Kumaş   │ │yon       │ │ Kumaş    │ │
│  └────────┘ └─────────┘ └──────────┘ └──────────┘ │
│  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Boya & │ │ Baskı & │ │ İplik    │ │ Teknik   │ │
│  │ Terbiye│ │ Desen   │ │ Üretim   │ │ Tekstil  │ │
│  └────────┘ └─────────┘ └──────────┘ └──────────┘ │
├─────────────────────────────────────────────────────┤
│  Veri Katmanı (Tenant İzolasyonu)                   │
│  ┌──────────────────────────────────────────────┐   │
│  │ Supabase + RLS (firma_id bazlı izolasyon)    │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 📌 AŞAMA 1: VERİTABANI MULTI-TENANT ALTYAPISI
**Süre Tahmini: ~2 hafta | Öncelik: KRİTİK**

Bu aşama tüm sistemin temelini oluşturur. Mevcut tek-firma yapısı, çoklu firma desteğine dönüştürülür.

### Adım 1.1: Firma (Tenant) Ana Tablosu Oluşturma
```sql
-- Firma/Tenant ana tablosu
CREATE TABLE firmalar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_adi VARCHAR(255) NOT NULL,
    firma_kodu VARCHAR(50) UNIQUE NOT NULL,  -- benzersiz firma kodu (URL slug)
    vergi_no VARCHAR(20),
    vergi_dairesi VARCHAR(100),
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(255),
    web VARCHAR(255),
    logo_url TEXT,
    sektor VARCHAR(100) DEFAULT 'tekstil',
    aktif BOOLEAN DEFAULT true,
    olusturma_tarihi TIMESTAMPTZ DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMPTZ DEFAULT NOW()
);

-- Firma ayarları (key-value, firma bazlı)
CREATE TABLE firma_ayarlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    anahtar VARCHAR(255) NOT NULL,
    deger TEXT,
    UNIQUE(firma_id, anahtar)
);
```

### Adım 1.2: Kullanıcı-Firma İlişki Tablosu Güncelleme
```sql
-- Mevcut firma_kullanicilari tablosunu yeniden yapılandır
CREATE TABLE firma_kullanicilari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rol VARCHAR(50) NOT NULL DEFAULT 'kullanici', 
    -- roller: firma_sahibi, firma_admin, yonetici, kullanici, personel
    yetki_grubu JSONB DEFAULT '[]',  -- ek yetkiler
    aktif BOOLEAN DEFAULT true,
    davet_tarihi TIMESTAMPTZ DEFAULT NOW(),
    katilim_tarihi TIMESTAMPTZ,
    UNIQUE(firma_id, user_id)
);

-- Bir kullanıcı birden fazla firmada olabilir
-- Aktif firma seçimi için session tablosu
CREATE TABLE kullanici_aktif_firma (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    son_giris TIMESTAMPTZ DEFAULT NOW()
);
```

### Adım 1.3: Mevcut Tablolara firma_id Ekleme
Tüm mevcut veri tablolarına `firma_id` kolonu eklenir:

```sql
-- ÖNEMLİ: Tüm ana veri tablolarına firma_id eklenmeli
ALTER TABLE triko_takip ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE modeller ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE personel ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE tedarikciler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE musteriler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE faturalar ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE fatura_kalemleri ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE kasa_banka_hesaplari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE kasa_banka_hareketleri ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE iplik_stoklari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE iplik_hareketleri ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE aksesuarlar ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE aksesuar_stok ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE urun_depo ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE sevkiyat_kayitlari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE sevkiyat_detaylari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE atolyeler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE dokuma_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE yikama_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE nakis_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE ilik_dugme_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE konfeksiyon_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE utu_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE paketleme_atamalari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE odeme_kayitlari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE mesai ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE puantaj ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE izinler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE bordro ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE bildirimler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE donemler ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE beden_tanimlari ADD COLUMN firma_id UUID REFERENCES firmalar(id);
ALTER TABLE stok_hareketleri ADD COLUMN firma_id UUID REFERENCES firmalar(id);
-- ... diğer tüm tablolar
```

### Adım 1.4: Row Level Security (RLS) Politikaları
```sql
-- Tüm tablolar için RLS aktifleştirme ve politika oluşturma
-- Örnek: triko_takip tablosu
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_izolasyonu_triko_takip" ON triko_takip
    USING (
        firma_id IN (
            SELECT firma_id FROM firma_kullanicilari 
            WHERE user_id = auth.uid() AND aktif = true
        )
    );

-- Bu pattern TÜM tablolara uygulanacak
-- Helper fonksiyon oluştur:
CREATE OR REPLACE FUNCTION get_user_firma_ids()
RETURNS SETOF UUID AS $$
    SELECT firma_id FROM firma_kullanicilari 
    WHERE user_id = auth.uid() AND aktif = true;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_active_firma_id()
RETURNS UUID AS $$
    SELECT firma_id FROM kullanici_aktif_firma 
    WHERE user_id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
```

### Adım 1.5: Mevcut Veri Migrasyonu
```sql
-- Mevcut verilerin ilk firmaya atanması
INSERT INTO firmalar (id, firma_adi, firma_kodu)
VALUES (gen_random_uuid(), 'Mevcut Firma', 'mevcut-firma');

-- Tüm mevcut kayıtlara bu firma_id atanır
UPDATE triko_takip SET firma_id = (SELECT id FROM firmalar LIMIT 1);
UPDATE personel SET firma_id = (SELECT id FROM firmalar LIMIT 1);
-- ... tüm tablolar için
```

---

## 📌 AŞAMA 2: MODÜL SİSTEMİ TASARIMI
**Süre Tahmini: ~2 hafta | Öncelik: KRİTİK**

### Adım 2.1: Modül Tanım Tabloları
```sql
-- Ana modül tanımları (platform tarafından yönetilir)
CREATE TABLE modul_tanimlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modul_kodu VARCHAR(50) UNIQUE NOT NULL,
    modul_adi VARCHAR(255) NOT NULL,
    aciklama TEXT,
    kategori VARCHAR(100) NOT NULL,
    -- kategoriler: uretim, finans, ik, stok, sevkiyat, rapor, crm
    ikon VARCHAR(100),
    sira_no INT DEFAULT 0,
    bagimliliklar JSONB DEFAULT '[]', -- bağımlı olduğu modül kodları
    aktif BOOLEAN DEFAULT true,
    ucret_tipi VARCHAR(50) DEFAULT 'aylik', -- aylik, kullanim_bazli, ucretsiz
    aylik_ucret DECIMAL(10,2) DEFAULT 0
);

-- Üretim alt-modülleri (tekstil dalları)
CREATE TABLE uretim_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modul_kodu VARCHAR(50) UNIQUE NOT NULL,
    modul_adi VARCHAR(255) NOT NULL,
    tekstil_dali VARCHAR(100) NOT NULL,
    -- dallar: triko, dokuma_kumas, konfeksiyon, orme_kumas, 
    --         boya_terbiye, baski_desen, iplik_uretim, teknik_tekstil
    aciklama TEXT,
    uretim_asamalari JSONB NOT NULL, -- bu dal için geçerli üretim aşamaları
    aktif BOOLEAN DEFAULT true
);

-- Firma-Modül ilişkisi (firma hangi modülleri kullanıyor)
CREATE TABLE firma_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    modul_id UUID NOT NULL REFERENCES modul_tanimlari(id),
    aktif BOOLEAN DEFAULT true,
    aktivasyon_tarihi TIMESTAMPTZ DEFAULT NOW(),
    bitis_tarihi TIMESTAMPTZ, -- null = süresiz
    UNIQUE(firma_id, modul_id)
);

-- Firma-Üretim Modülü ilişkisi
CREATE TABLE firma_uretim_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    uretim_modul_id UUID NOT NULL REFERENCES uretim_modulleri(id),
    aktif BOOLEAN DEFAULT true,
    ozel_asamalar JSONB, -- firma bu dalda özelleştirdiği aşamalar
    UNIQUE(firma_id, uretim_modul_id)
);
```

### Adım 2.2: Temel Modüller ve Üretim Dalları Tanımları

#### Ana Modüller:
| Modül Kodu | Modül Adı | Kategori | Açıklama |
|------------|-----------|----------|----------|
| `uretim` | Üretim Yönetimi | uretim | Ana üretim takip modülü (en az 1 üretim dalı seçilmeli) |
| `finans` | Finans & Muhasebe | finans | Fatura, kasa-banka, ödeme yönetimi |
| `ik` | İnsan Kaynakları | ik | Personel, maaş, puantaj, izin, mesai |
| `stok` | Stok & Depo | stok | Hammadde, aksesuar, ürün depo yönetimi |
| `sevkiyat` | Sevkiyat & Lojistik | sevkiyat | Sevkiyat planlama, takip, şoför paneli |
| `tedarik` | Tedarikçi Yönetimi | tedarik | Tedarikçi tanım, sipariş, ödeme |
| `musteri` | Müşteri Yönetimi | crm | Müşteri tanım, sipariş takip |
| `rapor` | Raporlar & Analiz | rapor | Gelişmiş raporlama, KPI, export |
| `kalite` | Kalite Kontrol | uretim | Kalite kontrol süreçleri |
| `ayarlar` | Sistem Ayarları | sistem | Firma ayarları, kullanıcı yönetimi |

#### Tekstil Üretim Dalları:
| Dal Kodu | Dal Adı | Üretim Aşamaları |
|----------|---------|-------------------|
| `triko` | Triko Üretim | Tasarım → Dokuma/Örme → Yıkama → Nakış → İlik Düğme → Konfeksiyon → Ütü → Paketleme → Kalite → Sevkiyat |
| `dokuma_kumas` | Dokuma Kumaş | Çözgü Hazırlama → Dokuma → Haşıl → Terbiye → Kalite → Depolama → Sevkiyat |
| `konfeksiyon` | Konfeksiyon (Hazır Giyim) | Tasarım → Kalıp → Kesim → Dikim → Ütü/Pres → Aksesuar → Kalite → Paketleme → Sevkiyat |
| `orme_kumas` | Örme Kumaş | İplik Hazırlama → Örme → Boyama → Terbiye → Kalite → Depolama → Sevkiyat |
| `boya_terbiye` | Boya & Terbiye | Malzeme Kabul → Ön Terbiye → Boyama → Baskı → Son Terbiye → Kalite → Sevkiyat |
| `baski_desen` | Baskı & Desen | Tasarım → Kalıp/Şablon → Baskı → Kurutma → Fiksaj → Kalite → Sevkiyat |
| `iplik_uretim` | İplik Üretim | Hammadde Kabul → Harman → Tarak → Fitil → Büküm → Bobin → Kalite → Sevkiyat |
| `teknik_tekstil` | Teknik Tekstil | Malzeme Seçim → Üretim → Kaplama/Laminasyon → Test → Kalite → Sevkiyat |

### Adım 2.3: Flutter Modül Registry Sistemi

```dart
// lib/config/module_registry.dart

/// Platform tarafından tanımlanan tüm modüller
enum AppModule {
  uretim('uretim', 'Üretim Yönetimi', Icons.factory, ModuleCategory.uretim),
  finans('finans', 'Finans & Muhasebe', Icons.account_balance, ModuleCategory.finans),
  ik('ik', 'İnsan Kaynakları', Icons.people, ModuleCategory.ik),
  stok('stok', 'Stok & Depo', Icons.inventory, ModuleCategory.stok),
  sevkiyat('sevkiyat', 'Sevkiyat & Lojistik', Icons.local_shipping, ModuleCategory.sevkiyat),
  tedarik('tedarik', 'Tedarikçi Yönetimi', Icons.handshake, ModuleCategory.tedarik),
  musteri('musteri', 'Müşteri Yönetimi', Icons.storefront, ModuleCategory.crm),
  rapor('rapor', 'Raporlar & Analiz', Icons.analytics, ModuleCategory.rapor),
  kalite('kalite', 'Kalite Kontrol', Icons.verified, ModuleCategory.uretim),
  ayarlar('ayarlar', 'Sistem Ayarları', Icons.settings, ModuleCategory.sistem);

  final String kod;
  final String ad;
  final IconData ikon;
  final ModuleCategory kategori;
  const AppModule(this.kod, this.ad, this.ikon, this.kategori);
}

/// Tekstil üretim dalları
enum TekstilDali {
  triko('triko', 'Triko Üretim'),
  dokumaKumas('dokuma_kumas', 'Dokuma Kumaş'),
  konfeksiyon('konfeksiyon', 'Konfeksiyon'),
  ormeKumas('orme_kumas', 'Örme Kumaş'),
  boyaTerbiye('boya_terbiye', 'Boya & Terbiye'),
  baskiDesen('baski_desen', 'Baskı & Desen'),
  iplikUretim('iplik_uretim', 'İplik Üretim'),
  teknikTekstil('teknik_tekstil', 'Teknik Tekstil');

  final String kod;
  final String ad;
  const TekstilDali(this.kod, this.ad);
}
```

---

## 📌 AŞAMA 3: FLUTTER MULTI-TENANT ALTYAPISI
**Süre Tahmini: ~2 hafta | Öncelik: KRİTİK**

### Adım 3.1: Tenant Provider (Firma Bağlamı)
```dart
// lib/providers/tenant_provider.dart

/// Aktif firma bağlamını yöneten provider
/// Tüm veri sorguları bu provider üzerinden firma_id alır
class TenantProvider extends ChangeNotifier {
  String? _firmaId;
  Map<String, dynamic>? _firmaDetay;
  List<Map<String, dynamic>> _kullaniciFirmalari = [];
  List<String> _aktifModuller = [];
  List<String> _aktifUretimDallari = [];

  String? get firmaId => _firmaId;
  String get firmaAdi => _firmaDetay?['firma_adi'] ?? '';
  List<String> get aktifModuller => _aktifModuller;
  List<String> get aktifUretimDallari => _aktifUretimDallari;
  bool get firmaSecildi => _firmaId != null;

  /// Kullanıcının erişebildiği firmaları yükle
  Future<void> kullaniciFirmalariniYukle(String userId);

  /// Aktif firmayı değiştir (firma arası geçiş)
  Future<void> firmaSecimi(String firmaId);

  /// Firma modüllerini yükle
  Future<void> modulleriYukle();

  /// Belirli modülün aktif olup olmadığını kontrol et
  bool modulAktifMi(String modulKodu);

  /// Belirli üretim dalının aktif olup olmadığını kontrol et
  bool uretimDaliAktifMi(String dalKodu);
}
```

### Adım 3.2: Servis Katmanında Tenant Filtresi (BaseService Pattern)
```dart
// lib/services/base_service.dart

/// Tüm servislerin extend edeceği temel sınıf
/// Otomatik firma_id filtresi uygular
abstract class BaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  /// Aktif firma ID'sini al
  String get firmaId {
    // Provider'dan veya context'ten al
    final tenantProvider = GetIt.instance<TenantProvider>();
    final id = tenantProvider.firmaId;
    if (id == null) throw Exception('Firma seçilmemiş');
    return id;
  }

  /// Firma filtreli sorgu oluştur
  PostgrestFilterBuilder<List<Map<String, dynamic>>> firmaQuery(String table) {
    return _client.from(table).select().eq('firma_id', firmaId);
  }

  /// Firma filtreli insert (otomatik firma_id ekler)
  Future<Map<String, dynamic>> firmaInsert(String table, Map<String, dynamic> data) {
    data['firma_id'] = firmaId;
    return _client.from(table).insert(data).select().single();
  }

  /// Firma filtreli update
  Future<void> firmaUpdate(String table, String id, Map<String, dynamic> data) {
    return _client.from(table).update(data).eq('id', id).eq('firma_id', firmaId);
  }

  /// Firma filtreli delete
  Future<void> firmaDelete(String table, String id) {
    return _client.from(table).delete().eq('id', id).eq('firma_id', firmaId);
  }
}
```

### Adım 3.3: Mevcut Servislerin Güncellenmesi
Her servis `BaseService`'den extend edilecek ve tüm sorgulara `firma_id` filtresi eklenecek:

```
Güncellenecek servisler:        Değişiklik:
─────────────────────────────   ───────────────────────────────
fatura_service.dart            → extends BaseService + firmaQuery
kasa_banka_service.dart        → extends BaseService + firmaQuery
kasa_banka_hareket_service.dart→ extends BaseService + firmaQuery
personel_service.dart          → extends BaseService + firmaQuery
odeme_service.dart             → extends BaseService + firmaQuery
mesai_service.dart             → extends BaseService + firmaQuery
izin_service.dart              → extends BaseService + firmaQuery
puantaj_service.dart           → extends BaseService + firmaQuery
tedarikci_service.dart         → extends BaseService + firmaQuery
beden_service.dart             → extends BaseService + firmaQuery
uretim_zinciri_service.dart    → extends BaseService + firmaQuery
uretim_raporu_service.dart     → extends BaseService + firmaQuery
rapor_servisleri.dart          → extends BaseService + firmaQuery
gelismis_rapor_servisleri.dart → extends BaseService + firmaQuery
supabase_service.dart          → extends BaseService + firmaQuery
notification_service.dart      → extends BaseService + firmaQuery
donem_service.dart             → extends BaseService + firmaQuery
model_maliyet_hesaplama.dart   → extends BaseService + firmaQuery
```

### Adım 3.4: Ana Uygulama Akışı Değişikliği

```
MEVCUT AKIŞ:
  Splash → Login → Rol Kontrolü → Dashboard

YENİ AKIŞ:
  Splash → Login → Firma Seçimi → Modül Kontrolü → Dashboard
                    ↑                                    │
                    └── Firma Değiştir ←─────────────────┘

DETAYLI YENİ AKIŞ:
  1. Splash Screen
     └→ Otomatik giriş kontrolü
  
  2. Login / Kayıt
     └→ Yeni kullanıcı: Firma oluştur VEYA davet kodu ile katıl
     └→ Mevcut kullanıcı: Auth doğrulama
  
  3. Firma Seçim Ekranı (kullanıcının birden fazla firması varsa)
     └→ Firma listesi göster
     └→ Yeni firma oluştur seçeneği
     └→ Tek firma varsa otomatik geç
  
  4. Firma Kurulum Sihirbazı (ilk kez ise)
     └→ Firma bilgileri
     └→ Tekstil dalı seçimi
     └→ Modül seçimi
     └→ İlk ayarlar
  
  5. Ana Dashboard
     └→ Sadece aktif modüller görünür
     └→ Üretim modülü: sadece seçilen dalın aşamaları
     └→ Firma ayarları ve modül yönetimi erişimi
```

---

## 📌 AŞAMA 4: KAYIT & FİRMA OLUŞTURMA SİSTEMİ
**Süre Tahmini: ~1.5 hafta | Öncelik: YÜKSEK**

### Adım 4.1: Yeni Kayıt Akışı Sayfaları

```
lib/pages/onboarding/
├── firma_kayit_page.dart         -- Firma oluşturma / katılma seçimi
├── firma_bilgileri_page.dart     -- Firma detayları formu
├── tekstil_dali_secim_page.dart  -- Üretim dalı/dalları seçimi
├── modul_secim_page.dart         -- Modül seçimi (check/uncheck)
├── firma_kurulum_ozet_page.dart  -- Özet ve onay
├── firma_secim_page.dart         -- Çoklu firma kullanıcıları için seçim
└── davet_katil_page.dart         -- Davet kodu ile firmaya katılma
```

### Adım 4.2: Firma Oluşturma Servisi
```dart
// lib/services/firma_service.dart
class FirmaService extends BaseService {
  /// Yeni firma oluştur ve sahibi olarak ata  
  Future<String> firmaOlustur({
    required String firmaAdi,
    required String firmaKodu,
    required Map<String, dynamic> firmaBilgileri,
    required List<String> secilenModuller,
    required List<String> secilenUretimDallari,
  });

  /// Kullanıcıyı firmaya davet et
  Future<void> kullaniciDavetEt(String email, String rol);

  /// Davet kabul et
  Future<void> davetKabulEt(String davetKodu);

  /// Firma modüllerini güncelle
  Future<void> modulleriGuncelle(List<String> modulKodlari);

  /// Firma üretim dallarını güncelle
  Future<void> uretimDallariniGuncelle(List<String> dalKodlari);
}
```

### Adım 4.3: Davet Sistemi
```sql
CREATE TABLE firma_davetleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    davet_eden_id UUID NOT NULL REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL,
    rol VARCHAR(50) DEFAULT 'kullanici',
    davet_kodu VARCHAR(20) UNIQUE NOT NULL,
    durum VARCHAR(20) DEFAULT 'beklemede', -- beklemede, kabul_edildi, suresi_doldu
    olusturma_tarihi TIMESTAMPTZ DEFAULT NOW(),
    gecerlilik_tarihi TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);
```

---

## 📌 AŞAMA 5: DİNAMİK DASHBOARD & MODÜL TABANLI NAVİGASYON
**Süre Tahmini: ~2 hafta | Öncelik: YÜKSEK**

### Adım 5.1: Modüler Dashboard Tasarımı

```dart
// lib/pages/home/ana_sayfa.dart değişiklikleri

/// Dashboard artık sabit kategoriler yerine,
/// firmanın aktif modüllerine göre dinamik oluşturulur
class AnaSayfa extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final tenant = Provider.of<TenantProvider>(context);
    final aktifModuller = tenant.aktifModuller;
    
    return Scaffold(
      appBar: _buildAppBar(tenant), // Firma adı, firma değiştir butonu
      drawer: _buildModulDrawer(aktifModuller), // Modül bazlı menü
      body: _buildDashboardGrid(aktifModuller), // Aktif modül kartları
    );
  }
}
```

### Adım 5.2: Dinamik Üretim Aşamaları

Mevcut sabit 10 aşamalı triko üretim hattı yerine, seçilen tekstil dalına göre dinamik aşamalar:

```dart
// lib/config/uretim_asamalari_registry.dart

/// Her tekstil dalı için üretim aşamalarını tanımlar
class UretimAsamalariRegistry {
  static List<UretimAsamasi> asamalariGetir(String tekstilDali) {
    switch (tekstilDali) {
      case 'triko':
        return _trikoAsamalari; // mevcut 10 aşama
      case 'konfeksiyon':
        return _konfeksiyonAsamalari;
      case 'dokuma_kumas':
        return _dokumaKumasAsamalari;
      // ... diğer dallar
    }
  }
}

class UretimAsamasi {
  final String kod;
  final String ad;
  final IconData ikon;
  final String tabloAdi; // hangi atama tablosunu kullanıyor
  final int siraNo;
  final bool zorunlu;
  final bool ozellestirilmis; // firma tarafından eklendi mi
}
```

### Adım 5.3: Route Sistemi Güncelleme

```dart
// lib/config/app_routes.dart - YENİ HALİ

class AppRoutes {
  // Platform rotaları (herkes için)
  static const splash = '/';
  static const login = '/login';
  static const register = '/kayit';
  static const firmaSecim = '/firma-secim';
  static const firmaOlustur = '/firma-olustur';
  static const onboarding = '/kurulum';
  
  // Modül rotaları (aktif modüllere göre)
  static const anasayfa = '/anasayfa';
  
  // Üretim modülü
  static const uretimDashboard = '/uretim';
  static const uretimAsama = '/uretim/asama/:asamaKodu';
  static const uretimRapor = '/uretim/rapor';
  static const modelDuzenle = '/uretim/model/:modelId';
  
  // Finans modülü
  static const faturaListesi = '/finans/faturalar';
  static const kasaBanka = '/finans/kasa-banka';
  
  // İK modülü
  static const personelListesi = '/ik/personel';
  static const bordro = '/ik/bordro';
  
  // Stok modülü
  static const stokYonetimi = '/stok';
  
  // Sevkiyat modülü
  static const sevkiyat = '/sevkiyat';
  
  // ... vs
  
  /// Modül bazlı erişim kontrolü
  static bool routeIzinliMi(String route, List<String> aktifModuller) {
    // Route'un ait olduğu modülü kontrol et
    // Modül aktif değilse erişim engelle
  }
}
```

### Adım 5.4: Modül Tabanlı Sidebar/Drawer Navigasyon

```dart
// lib/widgets/modul_navigation.dart

/// Firma'nın aktif modüllerine göre dinamik navigasyon menüsü
class ModulNavigation extends StatelessWidget {
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    
    return NavigationRail(
      destinations: [
        // Her zaman görünür
        _buildDestination('Ana Sayfa', Icons.dashboard),
        
        // Modül bazlı
        if (tenant.modulAktifMi('uretim'))
          _buildDestination('Üretim', Icons.factory),
        if (tenant.modulAktifMi('finans'))
          _buildDestination('Finans', Icons.account_balance),
        if (tenant.modulAktifMi('ik'))
          _buildDestination('İK', Icons.people),
        if (tenant.modulAktifMi('stok'))
          _buildDestination('Stok', Icons.inventory),
        if (tenant.modulAktifMi('sevkiyat'))
          _buildDestination('Sevkiyat', Icons.local_shipping),
        if (tenant.modulAktifMi('tedarik'))
          _buildDestination('Tedarikçi', Icons.handshake),
        if (tenant.modulAktifMi('musteri'))
          _buildDestination('Müşteri', Icons.storefront),
        if (tenant.modulAktifMi('rapor'))
          _buildDestination('Raporlar', Icons.analytics),
          
        // Her zaman görünür
        _buildDestination('Ayarlar', Icons.settings),
      ],
    );
  }
}
```

---

## 📌 AŞAMA 6: ABONELİK & ÜCRETLENDIRME SİSTEMİ
**Süre Tahmini: ~2 hafta | Öncelik: YÜKSEK**

### Adım 6.1: Abonelik Tabloları
```sql
-- Abonelik planları
CREATE TABLE abonelik_planlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_kodu VARCHAR(50) UNIQUE NOT NULL,
    plan_adi VARCHAR(255) NOT NULL,
    aciklama TEXT,
    aylik_ucret DECIMAL(10,2) NOT NULL,
    yillik_ucret DECIMAL(10,2), -- yıllık indirimli fiyat
    max_kullanici INT, -- null = sınırsız
    max_modul INT, -- null = sınırsız
    dahil_moduller JSONB DEFAULT '[]', -- planla birlikte gelen modüller
    ozellikler JSONB DEFAULT '{}', -- plan özellikleri
    aktif BOOLEAN DEFAULT true,
    sira_no INT DEFAULT 0
);

-- Firma abonelikleri
CREATE TABLE firma_abonelikleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES abonelik_planlari(id),
    durum VARCHAR(20) DEFAULT 'aktif', -- aktif, pasif, deneme, iptal
    baslangic_tarihi TIMESTAMPTZ DEFAULT NOW(),
    bitis_tarihi TIMESTAMPTZ,
    deneme_bitis TIMESTAMPTZ, -- ücretsiz deneme süresi
    odeme_periyodu VARCHAR(20) DEFAULT 'aylik', -- aylik, yillik
    son_odeme_tarihi TIMESTAMPTZ,
    sonraki_odeme_tarihi TIMESTAMPTZ,
    iptal_tarihi TIMESTAMPTZ,
    UNIQUE(firma_id) -- bir firmanın tek aktif aboneliği olur
);

-- Ödeme geçmişi
CREATE TABLE abonelik_odemeleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id),
    abonelik_id UUID NOT NULL REFERENCES firma_abonelikleri(id),
    tutar DECIMAL(10,2) NOT NULL,
    para_birimi VARCHAR(3) DEFAULT 'TRY',
    odeme_tarihi TIMESTAMPTZ DEFAULT NOW(),
    odeme_yontemi VARCHAR(50), -- kredi_karti, havale, stripe, iyzico
    odeme_referans VARCHAR(255),
    durum VARCHAR(20) DEFAULT 'basarili', -- basarili, basarisiz, beklemede, iade
    fatura_no VARCHAR(50)
);
```

### Adım 6.2: Abonelik Planları

| Plan | Aylık Ücret | Kullanıcı | Modül | Özellikler |
|------|-------------|-----------|-------|------------|
| **Başlangıç** | ₺499 | 3 | 3 | Temel üretim + 1 dal |
| **Profesyonel** | ₺999 | 10 | 6 | Çoklu dal + raporlama |
| **Kurumsal** | ₺1.999 | 25 | Tümü | Tüm dallar + API + destek |
| **Enterprise** | Özel | Sınırsız | Sınırsız | Özel geliştirme + SLA |
| **Deneme** | Ücretsiz | 2 | 3 | 14 gün deneme |

### Adım 6.3: Ödeme Entegrasyonu (Stripe/iyzico)
```dart
// lib/services/abonelik_service.dart
class AbonelikService {
  /// Mevcut abonelik durumunu kontrol et
  Future<AbonelikDurumu> abonelikKontrol(String firmaId);
  
  /// Plan değiştir
  Future<void> planDegistir(String yeniPlanId);
  
  /// Ödeme başlat (Stripe/iyzico entegrasyonu)
  Future<String> odemeBaslat(OdemeDetay detay);
  
  /// Abonelik iptal
  Future<void> abonelikIptal();
  
  /// Deneme süresi başlat
  Future<void> denemeSuresiBaslat(String firmaId);
  
  /// Modül bazlı erişim kontrolü (abonelik limitlerine göre)
  bool modulErisimKontrol(String modulKodu);
}
```

### Adım 6.4: Abonelik Sayfaları
```
lib/pages/abonelik/
├── plan_secim_page.dart        -- Plan karşılaştırma ve seçim
├── odeme_page.dart             -- Ödeme formu
├── abonelik_yonetimi_page.dart -- Mevcut abonelik yönetimi
├── fatura_gecmisi_page.dart    -- Ödeme/fatura geçmişi
└── plan_degistir_page.dart     -- Plan upgrade/downgrade
```

---

## 📌 AŞAMA 7: KULLANICI YÖNETİMİ & ROL SİSTEMİ GÜNCELLEMESİ
**Süre Tahmini: ~1.5 hafta | Öncelik: YÜKSEK**

### Adım 7.1: Yeni Rol Hiyerarşisi

```
PLATFORM SEVİYESİ:
  platform_admin     → Tüm sistemi yönetir (SaaS yöneticisi)

FİRMA SEVİYESİ:
  firma_sahibi       → Firmayı oluşturan kişi, tam yetki
  firma_admin        → Firma yöneticisi, modül/kullanıcı yönetimi
  yonetici           → Departman/birim yöneticisi
  kullanici          → Standart kullanıcı
  personel           → Sadece kendi bilgilerini görür
  
ÖZEL ROLLER (üretim dalına göre dinamik):
  dokumaci           → Dokuma dashboard erişimi
  konfeksiyoncu      → Konfeksiyon dashboard erişimi
  kalite_kontrol     → Kalite kontrol paneli
  sofor              → Sevkiyat/şoför paneli
  muhasebeci         → Finans modülü erişimi
  depocu             → Stok modülü erişimi
```

### Adım 7.2: Yetki Matrisi Tablosu
```sql
-- Modül-Rol bazlı yetki tanımları  
CREATE TABLE yetki_tanimlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID REFERENCES firmalar(id) ON DELETE CASCADE,
    -- firma_id NULL ise platform varsayılanı
    rol VARCHAR(50) NOT NULL,
    modul_kodu VARCHAR(50) NOT NULL,
    yetki VARCHAR(50) NOT NULL, -- okuma, yazma, silme, yonetim, export
    aktif BOOLEAN DEFAULT true,
    UNIQUE(firma_id, rol, modul_kodu, yetki)
);
```

### Adım 7.3: AuthProvider Güncelleme
```dart
// lib/providers/auth_provider.dart - Genişletilmiş

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _firmaRol;           // firmadaki rolü
  String? _platformRol;        // platform rolü (admin vs normal)
  List<String> _yetkiler = []; // firma+modül bazlı yetkiler
  
  bool yetkiVarMi(String modulKodu, String yetki) {
    if (_firmaRol == 'firma_sahibi' || _firmaRol == 'firma_admin') return true;
    return _yetkiler.contains('$modulKodu:$yetki');
  }
  
  bool modulErisimVarMi(String modulKodu) {
    return yetkiVarMi(modulKodu, 'okuma');
  }
}
```

---

## 📌 AŞAMA 8: ÜRETİM MODÜLÜ GENELLEŞTİRME
**Süre Tahmini: ~3 hafta | Öncelik: YÜKSEK**

### Adım 8.1: Mevcut Triko-Spesifik Kodun Soyutlanması

Mevcut yapıda triko üretimine özgü alanlar (trikoTipi, iplik bilgileri, vb.) genelleştirilecek:

```dart
// MEVCUT (triko'ya özgü):
class SiparisModel {
  final String? trikoTipi;
  final String? iplikTuru;
  final String? iplikKompozisyonu;
  // ...
}

// YENİ (genel tekstil):
class SiparisModel {
  final String? uretimDali;          // triko, konfeksiyon, dokuma...
  final String? urunTipi;            // dalın alt tipi
  final Map<String, dynamic>? dalOzelAlanlar; // dal'a özgü ek alanlar (JSONB)
  // Ortak alanlar korunur: marka, kalemNo, modelAdi, bedenler, renk, vb.
}
```

### Adım 8.2: Dinamik Form Alanları (Dal Bazlı)

```dart
// lib/config/dal_form_alanlari.dart

/// Her tekstil dalı için özel form alanlarını tanımlar
class DalFormAlanlari {
  static List<FormAlan> alanlariGetir(String tekstilDali) {
    switch (tekstilDali) {
      case 'triko':
        return [
          FormAlan('triko_tipi', 'Triko Tipi', FormTipi.dropdown, 
            secenekler: ['Düz Örme', 'Jakar', 'İntarsia', 'Triko Kumaş']),
          FormAlan('iplik_turu', 'İplik Türü', FormTipi.text),
          FormAlan('iplik_numarasi', 'İplik Numarası', FormTipi.text),
          FormAlan('makine_tipi', 'Makine Tipi', FormTipi.dropdown),
          FormAlan('igne_inceligi', 'İğne İnceliği (Gauge)', FormTipi.number),
          // ...mevcut triko alanları
        ];
      case 'konfeksiyon':
        return [
          FormAlan('kumas_tipi', 'Kumaş Tipi', FormTipi.dropdown,
            secenekler: ['Dokuma', 'Örme', 'Denim', 'Kadife', 'Diğer']),
          FormAlan('kumas_gramaj', 'Kumaş Gramajı (g/m²)', FormTipi.number),
          FormAlan('kalip_tipi', 'Kalıp Tipi', FormTipi.dropdown),
          FormAlan('dikim_tipi', 'Dikim Tipi', FormTipi.dropdown),
          // ...konfeksiyon alanları
        ];
      case 'dokuma_kumas':
        return [
          FormAlan('cozgu_iplik', 'Çözgü İpliği', FormTipi.text),
          FormAlan('atki_iplik', 'Atkı İpliği', FormTipi.text),
          FormAlan('dokuma_tipi', 'Dokuma Tipi', FormTipi.dropdown),
          FormAlan('en_cm', 'Kumaş Eni (cm)', FormTipi.number),
          FormAlan('gramaj', 'Gramaj (g/m²)', FormTipi.number),
          // ...dokuma kumaş alanları
        ];
      // ... diğer dallar
    }
  }
}
```

### Adım 8.3: Genel Atama Tablosu (Tüm Dallar İçin)

Mevcut 8 ayrı atama tablosu (dokuma_atamalari, kalite_kontrol_atamalari, vb.) yerine genel bir atama tablosu:

```sql
-- Tüm üretim aşamaları için tek atama tablosu
CREATE TABLE uretim_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id),
    siparis_id UUID NOT NULL, -- ana sipariş referansı
    uretim_dali VARCHAR(50) NOT NULL, -- triko, konfeksiyon, vb.
    asama_kodu VARCHAR(50) NOT NULL, -- dokuma, kesim, dikim, vb.
    asama_sira_no INT NOT NULL,
    atanan_email VARCHAR(255),
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_tedarikci_id UUID REFERENCES tedarikciler(id),
    adet INT DEFAULT 0,
    tamamlanan_adet INT DEFAULT 0,
    fire_adet INT DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'atandi',
    -- atandi, basladi, devam_ediyor, tamamlandi, iptal
    baslama_tarihi TIMESTAMPTZ,
    bitis_tarihi TIMESTAMPTZ,
    notlar TEXT,
    ozel_alanlar JSONB, -- aşamaya özgü ek veriler
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOT: Mevcut atama tabloları (dokuma_atamalari, vb.) korunur
-- ve migration ile bu yeni tabloya taşınır.
-- Geriye uyumluluk için view'lar oluşturulabilir.
```

### Adım 8.4: Dinamik Dashboard Sistemi

```dart
// lib/pages/uretim/genel_uretim_dashboard.dart

/// Tekstil dalına göre dinamik üretim dashboard'u
class GenelUretimDashboard extends StatelessWidget {
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final aktifDallar = tenant.aktifUretimDallari;
    
    // Birden fazla dal aktifse: dal seçim tab'ları göster
    // Tek dal aktifse: direkt o dalın dashboard'unu göster
    
    return DefaultTabController(
      length: aktifDallar.length,
      child: Column(
        children: [
          if (aktifDallar.length > 1) TabBar(...), // Dal seçimi
          Expanded(
            child: TabBarView(
              children: aktifDallar.map((dal) => 
                UretimDaliDashboard(tekstilDali: dal)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Belirli bir tekstil dalı için üretim aşamalarını gösteren dashboard
class UretimDaliDashboard extends StatelessWidget {
  final String tekstilDali;
  
  Widget build(BuildContext context) {
    final asamalar = UretimAsamalariRegistry.asamalariGetir(tekstilDali);
    
    return GridView.builder(
      itemCount: asamalar.length,
      itemBuilder: (context, index) {
        return UretimAsamaKarti(asama: asamalar[index]);
      },
    );
  }
}
```

---

## 📌 AŞAMA 9: PLATFORM YÖNETİM PANELİ (SUPER ADMIN)
**Süre Tahmini: ~1.5 hafta | Öncelik: ORTA**

### Adım 9.1: Platform Admin Sayfaları
```
lib/pages/platform_admin/
├── platform_dashboard.dart     -- Genel platform istatistikleri
├── firma_listesi_page.dart     -- Tüm firmaları listeleme
├── firma_detay_admin.dart      -- Firma detay ve yönetim
├── abonelik_yonetimi.dart      -- Abonelik takip ve müdahale
├── modul_yonetimi.dart         -- Modül tanım ve fiyatlandırma
├── uretim_dali_yonetimi.dart   -- Üretim dalı tanım yönetimi
├── platform_raporlari.dart     -- Platform seviyesi raporlar
├── gelir_raporlari.dart        -- Gelir/abonelik raporları
└── destek_talepleri.dart       -- Firma destek talepleri
```

### Adım 9.2: Platform Dashboard İstatistikleri
```
- Toplam firma sayısı (aktif/pasif)
- Toplam kullanıcı sayısı
- Aktif abonelik dağılımı (plan bazlı)
- Aylık gelir / MRR (Monthly Recurring Revenue)
- Churn rate (iptal oranı)
- En çok kullanılan modüller
- En çok seçilen tekstil dalları
- Yeni kayıt trendi
```

---

## 📌 AŞAMA 10: VERİ MİGRASYONU & GERİYE UYUMLULUK
**Süre Tahmini: ~1 hafta | Öncelik: YÜKSEK**

### Adım 10.1: Migrasyon Stratejisi
```
1. Mevcut firma verilerini "Varsayılan Firma" olarak firmalar tablosuna ekle
2. Tüm mevcut kayıtlara firma_id ata
3. Mevcut kullanıcıları firma_kullanicilari tablosuna ekle
4. Mevcut rolleri yeni yapıya eşle
5. Triko üretim dalını mevcut firma için aktif modül olarak ata
6. Mevcut atama tablolarını olduğu gibi koru + yeni genel tabloya da kopyala
7. View'lar ile geriye uyumluluk sağla
```

### Adım 10.2: Migrasyon SQL Script'i (Aşamalı)
```sql
-- Fase 1: Yeni tablolar oluştur (mevcut verilere dokunma)
-- Fase 2: Varsayılan firma oluştur ve firma_id kolonları ekle
-- Fase 3: Mevcut verilere firma_id ata
-- Fase 4: firma_id NOT NULL constraint ekle
-- Fase 5: RLS politikalarını aktifleştir
-- Fase 6: Eski tabloları view olarak yeniden oluştur (geriye uyumluluk)
```

---

## 📌 AŞAMA 11: TEST & KALİTE GÜVENCE
**Süre Tahmini: ~1.5 hafta | Öncelik: YÜKSEK**

### Adım 11.1: Test Stratejisi
```
1. Unit testler:
   - TenantProvider testleri
   - BaseService firma_id filtresi testleri
   - Modül erişim kontrol testleri
   - Abonelik kontrol testleri
   
2. Integration testler:
   - Firma oluşturma akışı
   - Kullanıcı davet ve katılma
   - Firma değiştirme
   - Modül aktivasyon/deaktivasyon
   - Veri izolasyonu (Firma A'nın verisi Firma B'ye görünmemeli)
   
3. E2E testler:
   - Kayıt → Firma oluştur → Modül seç → Dashboard
   - Çoklu firma senaryosu
   - Abonelik ödeme akışı
```

### Adım 11.2: Mevcut Testlerin Güncellenmesi
Mevcut 106 test, firma_id mock'u ile güncellenecek:
```dart
// test/helpers/test_tenant.dart
class TestTenantHelper {
  static const testFirmaId = 'test-firma-uuid';
  static TenantProvider createMockTenant() {
    // Test firması ile mock tenant provider
  }
}
```

---

## 📌 AŞAMA 12: DEPLOYMENT & ALTYAPI
**Süre Tahmini: ~1 hafta | Öncelik: ORTA**

### Adım 12.1: Supabase Edge Functions
```
supabase/functions/
├── firma-olustur/          -- Firma oluşturma (DB transaction)
├── kullanici-davet/        -- Davet e-postası gönderme
├── abonelik-kontrol/       -- Periyodik abonelik kontrolü
├── odeme-webhook/          -- Stripe/iyzico webhook handler
├── modul-aktivasyon/       -- Modül aktivasyon/deaktivasyon
└── platform-rapor/         -- Platform istatistik hesaplama
```

### Adım 12.2: Web Deployment
```
- Supabase (mevcut, backend)
- Vercel veya Firebase Hosting (Flutter Web)
- Custom domain (texpilot.com veya benzeri)
- SSL sertifika
- CDN konfigürasyonu
```

---

## 🗓️ UYGULAMA TAKVİMİ (ÖNERİLEN SIRALAMA)

```
═══════════════════════════════════════════════════════════════════
 AŞAMA                                    │ BAĞIMLILIK  │ ÖNCELİK
═══════════════════════════════════════════════════════════════════
 1. Veritabanı Multi-Tenant Altyapısı     │ -           │ KRİTİK
 2. Modül Sistemi Tasarımı                │ Aşama 1     │ KRİTİK
 3. Flutter Multi-Tenant Altyapısı        │ Aşama 1,2   │ KRİTİK
 4. Kayıt & Firma Oluşturma              │ Aşama 1,2,3 │ YÜKSEK
 5. Dinamik Dashboard & Navigasyon        │ Aşama 2,3   │ YÜKSEK
 6. Abonelik & Ücretlendirme             │ Aşama 1,4   │ YÜKSEK
 7. Kullanıcı Yönetimi & Rol Güncelleme  │ Aşama 1,3   │ YÜKSEK
 8. Üretim Modülü Genelleştirme          │ Aşama 2,3,5 │ YÜKSEK
 9. Platform Yönetim Paneli              │ Aşama 1-7   │ ORTA
10. Veri Migrasyonu & Geriye Uyumluluk    │ Aşama 1-3   │ YÜKSEK
11. Test & Kalite Güvence                 │ Aşama 1-8   │ YÜKSEK
12. Deployment & Altyapı                  │ Aşama 1-11  │ ORTA
═══════════════════════════════════════════════════════════════════
```

---

## 📁 YENİ DOSYA YAPISI (lib/ dizini)

```
lib/
├── main.dart                         (güncelleme: tenant başlatma)
├── config/
│   ├── app_routes.dart               (güncelleme: modül bazlı rotalar)
│   ├── database_tables.dart          (güncelleme: yeni tablolar)
│   ├── supabase_config.dart          (mevcut)
│   ├── secure_storage.dart           (mevcut)
│   ├── module_registry.dart          (YENİ: modül tanımları)
│   └── uretim_asamalari_registry.dart(YENİ: dal bazlı aşamalar)
├── models/
│   ├── firma_model.dart              (YENİ)
│   ├── modul_model.dart              (YENİ)
│   ├── abonelik_model.dart           (YENİ)
│   ├── davet_model.dart              (YENİ)
│   ├── uretim_asamasi_model.dart     (YENİ)
│   ├── siparis_model.dart            (güncelleme: genel tekstil)
│   └── ... (mevcut modeller güncelleme)
├── providers/
│   ├── auth_provider.dart            (güncelleme: firma rol sistemi)
│   ├── tenant_provider.dart          (YENİ: firma bağlamı)
│   └── module_provider.dart          (YENİ: modül durumu)
├── services/
│   ├── base_service.dart             (YENİ: firma filtreli temel servis)
│   ├── firma_service.dart            (YENİ: firma CRUD)
│   ├── abonelik_service.dart         (YENİ: abonelik yönetimi)
│   ├── modul_service.dart            (YENİ: modül yönetimi)
│   ├── davet_service.dart            (YENİ: davet sistemi)
│   └── ... (mevcut servisler güncelleme: BaseService extend)
├── pages/
│   ├── onboarding/                   (YENİ: kayıt & kurulum)
│   │   ├── firma_kayit_page.dart
│   │   ├── firma_bilgileri_page.dart
│   │   ├── tekstil_dali_secim_page.dart
│   │   ├── modul_secim_page.dart
│   │   ├── firma_kurulum_ozet_page.dart
│   │   ├── firma_secim_page.dart
│   │   └── davet_katil_page.dart
│   ├── abonelik/                     (YENİ: abonelik yönetimi)
│   │   ├── plan_secim_page.dart
│   │   ├── odeme_page.dart
│   │   ├── abonelik_yonetimi_page.dart
│   │   └── fatura_gecmisi_page.dart
│   ├── platform_admin/               (YENİ: SaaS yönetim)
│   │   ├── platform_dashboard.dart
│   │   ├── firma_listesi_page.dart
│   │   └── ...
│   ├── home/                         (güncelleme: modüler dashboard)
│   ├── uretim/                       (güncelleme: genel üretim sistemi)
│   └── ... (mevcut modüller korunur)
└── widgets/
    ├── modul_navigation.dart         (YENİ: dinamik navigasyon)
    ├── firma_secici.dart             (YENİ: firma değiştirme widget)
    ├── modul_guard.dart              (YENİ: modül erişim kontrolü)
    └── ... (mevcut widgetlar korunur)
```

---

## ⚠️ KRİTİK NOTLAR & RİSKLER

### Güvenlik
1. **RLS ZORUNLU AKTİFLEŞTİRİLMELİ** — mevcut RLS kapalı durumu SaaS için kabul edilemez
2. **`kendimiAdminYap()` fonksiyonu silinmeli** — güvenlik açığı
3. **Service role key production'da kullanılmamalı** — Edge Functions'a taşınmalı
4. **Firma izolasyonu hem RLS hem uygulama seviyesinde** çift katmanlı olmalı

### Performans
1. **firma_id indeksleri** — tüm tablolarda firma_id + sık sorgulanan alanlar için composite index
2. **Connection pooling** — çoklu firma = çok daha fazla bağlantı
3. **Caching** — firma bazlı modül/ayar cache'leme

### Veri Bütünlüğü
1. **Migrasyon geri alınabilir olmalı** — her adım rollback planı ile
2. **Mevcut veriler korunmalı** — tek firma olarak devam edebilmeli
3. **Cross-tenant veri sızıntısı testleri** zorunlu

### İş Kuralları
1. Firma silme → soft-delete (veri 90 gün tutulur, sonra kalıcı silme)
2. Abonelik sona erdiğinde → okuma moduna geç, veri silinmez
3. Modül deaktif edildiğinde → veri korunur, sadece erişim engellenir

---

## 🎯 İLK ADIM: NEREDEN BAŞLAMALI?

**Önerilen başlangıç sırası:**

### ADIM 1 → Veritabanı hazırlığı (Bu aşamada başla)
1. `firmalar` tablosunu oluştur
2. `firma_kullanicilari` tablosunu düzenle
3. `modul_tanimlari` ve `uretim_modulleri` tablolarını oluştur
4. Mevcut tablolara `firma_id` ekle (nullable başlat)
5. Varsayılan firmayı oluştur ve mevcut verilere ata

### ADIM 2 → Flutter altyapısı
1. `TenantProvider` oluştur
2. `BaseService` oluştur
3. Mevcut servisleri BaseService'den extend et
4. `main.dart` akışını güncelle

### ADIM 3 → UI
1. Firma seçim ekranı
2. Dinamik dashboard
3. Modül bazlı navigasyon

Bu plan, mevcut çalışan sistemi bozmadan, aşamalı olarak SaaS platformuna dönüştürmeyi hedefler.
