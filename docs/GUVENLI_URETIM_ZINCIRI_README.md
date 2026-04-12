# Güvenli Üretim Zinciri Sistemi

## 🔒 Güvenlik Özellikleri

### ✅ Email Bazlı Atama
- **Güvenli**: User ID yerine email kullanılır
- **Pratik**: Email kolayca hatırlanır ve paylaşılır
- **Takip Edilebilir**: Her atama email ile kayıt altında

### ✅ Firma İzolasyonu
- **Sadece Atananlar Görür**: Her kullanıcı sadece kendine atanan modelleri görebilir
- **Rol Bazlı Erişim**: Dokuma personeli sadece dokuma işlerini, konfeksiyon sadece konfeksiyon işlerini görebilir
- **Admin İstisnası**: Admin kullanıcılar tüm işlemleri görebilir

### ✅ Database Güvenliği
- **RLS Politikaları**: Row Level Security ile data izolasyonu
- **Fonksiyon Kontrolü**: SECURITY DEFINER ile güvenli fonksiyonlar
- **Rol Doğrulama**: Her işlem öncesi rol kontrolü

## 📋 Sistem Bileşenleri

### 1. Database Fonksiyonları
```sql
-- Email'den UUID bulma
public.get_user_by_email(email_addr TEXT) → UUID

-- Rol kontrolü
public.check_user_role(email_addr TEXT, expected_role TEXT) → BOOLEAN

-- Model atama
public.assign_model_to_user(model_ids INT[], assignee_email TEXT, stage_name TEXT, notes TEXT) → JSON

-- Atanmış modelleri getirme
public.get_assigned_models(stage_name TEXT) → TABLE
```

### 2. Flutter Service
```dart
UretimZinciriService:
- assignModelsToUser() // Email bazlı atama
- getAssignedModels() // Kullanıcının atanan modelleri
- getStagePersonnel() // Aşama personeli listesi
- updateModelStatus() // Durum güncelleme
- checkUserRole() // Rol kontrolü
```

### 3. UI Bileşenleri
```dart
GuvenliAtamaDialog:
- Email bazlı personel seçimi
- Aşama seçimi
- Güvenlik kontrolleri

GuvenliUretimDashboard:
- Sadece atanan modeller
- Durum bazlı tab'lar
- Güvenli işlem butonları
```

## 🔧 Kurulum

### 1. Database Setup
```sql
-- 1. Güvenlik sistemini kur
\i uretim_zinciri_guvenlik_sistemi.sql

-- 2. Test et
SELECT public.get_user_by_email('test@firma.com');
SELECT public.check_user_role('test@firma.com', 'dokuma');
```

### 2. Flutter Entegrasyonu
```dart
// Service'i dahil et
import '../services/uretim_zinciri_service.dart';

// Dialog kullan
final result = await showDialog(
  context: context,
  builder: (context) => GuvenliAtamaDialog(
    seciliModelIdleri: [1, 2, 3],
    varsayilanAsama: 'dokuma',
  ),
);

// Dashboard kullan
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => GuvenliUretimDashboard(asamaAdi: 'dokuma'),
  ),
);
```

## 🎯 Kullanım Senaryoları

### Senaryo 1: Admin Model Ataması
1. Admin modelleri seçer
2. `GuvenliAtamaDialog` açar
3. Aşama seçer (dokuma, konfeksiyon, vs.)
4. Email ile personel seçer
5. Sistem otomatik rol kontrolü yapar
6. Atama gerçekleşir

### Senaryo 2: Personel Kendi İşlerini Görür
1. Dokuma personeli giriş yapar
2. `GuvenliUretimDashboard` açar
3. Sadece kendine atanan modelleri görür
4. Durum güncellemesi yapabilir
5. Başka aşamaların işlerini göremez

### Senaryo 3: Firma İzolasyonu
1. Firma A personeli: Sadece Firma A modellerini görebilir
2. Firma B personeli: Sadece Firma B modellerini görebilir
3. Çapraz erişim mümkün değil
4. Admin tüm firmaları görebilir

## 🛡️ Güvenlik Kontrolleri

### Database Seviyesi
- RLS politikaları aktif
- user_id = auth.uid() kontrolleri
- Role-based access control
- SECURITY DEFINER fonksiyonlar

### Uygulama Seviyesi
- Email doğrulama
- Rol kontrolü
- UI seviyesinde erişim kısıtlama
- Hata yakalama ve logging

### Veri Güvenliği
- Kullanıcı sadece kendi verilerini görebilir
- Email maskeleme (opsiyonel)
- Audit trail (atama geçmişi)
- Secure communication

## 📊 Avantajlar

### Admin İçin
- ✅ Merkezi atama sistemi
- ✅ Email bazlı kolay personel seçimi
- ✅ Güvenli rol yönetimi
- ✅ Şeffaf işlem takibi

### Üretim Personeli İçin
- ✅ Sadece kendi işlerini görür
- ✅ Karışıklık olmaz
- ✅ Basit arayüz
- ✅ Hızlı durum güncellemesi

### Firma İçin
- ✅ Veri güvenliği
- ✅ İş takibi
- ✅ Performans ölçümü
- ✅ Compliance sağlama

## 🔄 Workflow

```
[Admin] → Model Seçer → Aşama Belirler → Email ile Personel Atar
                                              ↓
[Personel] → Dashboard'a Girer → Sadece Kendi İşlerini Görür → Durum Günceller
                                              ↓
[Sistem] → RLS Kontrol → Role Check → Data Filter → UI Render
```

## 🚀 Genişletme Olanakları

- **Multi-tenant support**: Firma bazlı tam izolasyon
- **Approval workflow**: Atama onay sistemi
- **Real-time notifications**: Anlık bildirimler
- **Advanced reporting**: Detaylı raporlama
- **Mobile optimization**: Mobil arayüz iyileştirmeleri

---

Bu sistem **email bazlı atama** ile **firma izolasyonu** sağlayarak güvenli ve yönetilebilir bir üretim zinciri oluşturur.
