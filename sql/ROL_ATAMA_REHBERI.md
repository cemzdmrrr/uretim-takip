# Kullanıcı Rol Atama Rehberi

## 1. Kendi UUID'nizi Bulma

Supabase Dashboard'da SQL Editor'e gidin ve aşağıdaki komutu çalıştırın:

```sql
-- Mevcut kullanıcınızın UUID'sini bulmak için
SELECT auth.uid(), auth.email();
```

Bu komut size UUID'nizi ve email adresinizi döndürecektir.

## 2. Rol Atama SQL Komutları

### A) Admin Rolü Atama (Tüm yetkilere sahip)

```sql
-- Kendi kendinize admin rolü atamak için:
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES (auth.uid(), 'admin', 3);
```

### B) Belirli Bir Kullanıcıya Rol Atama

```sql
-- Başka bir kullanıcıya rol atamak için (UUID'yi değiştirin):
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('KULLANICI_UUID_BURAYA', 'kalite_kontrolu', 2);
```

## 3. Mevcut Rolleri Görüntüleme

```sql
-- Tüm kullanıcı rollerini görmek için:
SELECT 
    ur.id,
    au.email,
    ur.role,
    ur.yetki_seviyesi,
    a.atolye_adi,
    ur.created_at
FROM user_roles ur
LEFT JOIN auth.users au ON ur.user_id = au.id
LEFT JOIN atolyeler a ON ur.atolye_id = a.id
ORDER BY ur.created_at DESC;
```

## 4. Rol Türleri ve Yetki Seviyeleri

### Rol Türleri:
- `admin` - Sistem yöneticisi (tüm yetkiler)
- `kalite_kontrolu` - Kalite kontrol personeli
- `sevkiyat_yoneticisi` - Sevkiyat sorumlusu
- `atolye_yoneticisi` - Atölye yöneticisi
- `user` - Standart kullanıcı

### Yetki Seviyeleri:
- `1` - Temel yetki (sadece görüntüleme)
- `2` - Orta yetki (düzenleme + onay)
- `3` - Yüksek yetki (admin seviyesi)

## 5. Atölye Bazlı Rol Atama

```sql
-- Önce mevcut atölyeleri görün:
SELECT id, atolye_adi FROM atolyeler;

-- Belirli bir atölyeye kullanıcı atamak için:
INSERT INTO user_roles (user_id, role, atolye_id, yetki_seviyesi) 
VALUES ('KULLANICI_UUID', 'atolye_yoneticisi', ATOLYE_ID, 2);
```

## 6. Örnek Kullanım Senaryoları

### A) Kalite Kontrol Personeli Ekleme:
```sql
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('12345678-1234-1234-1234-123456789012', 'kalite_kontrolu', 2);
```

### B) Atölye Yöneticisi Ekleme:
```sql
-- Önce atölye ID'sini bulun
SELECT id, atolye_adi FROM atolyeler WHERE atolye_adi LIKE '%kesim%';

-- Sonra rolü atayın
INSERT INTO user_roles (user_id, role, atolye_id, yetki_seviyesi) 
VALUES ('12345678-1234-1234-1234-123456789012', 'atolye_yoneticisi', 1, 2);
```

### C) Sevkiyat Yöneticisi Ekleme:
```sql
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES ('12345678-1234-1234-1234-123456789012', 'sevkiyat_yoneticisi', 3);
```

## 7. Rol Güncelleme ve Silme

### Rol Güncelleme:
```sql
UPDATE user_roles 
SET role = 'admin', yetki_seviyesi = 3 
WHERE user_id = 'KULLANICI_UUID';
```

### Rol Silme:
```sql
DELETE FROM user_roles 
WHERE user_id = 'KULLANICI_UUID' AND role = 'user';
```

## 8. Hızlı Başlangıç

Yeni sistemi hemen kullanmaya başlamak için:

1. **Kendi kendinizi admin yapın:**
```sql
INSERT INTO user_roles (user_id, role, yetki_seviyesi) 
VALUES (auth.uid(), 'admin', 3);
```

2. **Test verileri oluşturun:**
```sql
-- Test atölyesi ekleyin
INSERT INTO atolyeler (atolye_adi, aciklama) 
VALUES ('Test Atölyesi', 'Test için oluşturuldu');

-- Test sevkiyat talebi oluşturun
INSERT INTO sevk_talepleri (model_id, talep_eden_id, hedef_atolye_id, miktar, aciklama)
VALUES (
    (SELECT id FROM triko_takip LIMIT 1),
    auth.uid(),
    (SELECT id FROM atolyeler ORDER BY id DESC LIMIT 1),
    10,
    'Test sevkiyat talebi'
);
```

## 9. Sorun Giderme

### UUID bulunamıyor hatası:
```sql
-- Tüm kullanıcıları listeleyin:
SELECT id, email FROM auth.users;
```

### Dublicate key hatası:
```sql
-- Mevcut rolünüzü güncelleyin:
UPDATE user_roles 
SET role = 'admin', yetki_seviyesi = 3 
WHERE user_id = auth.uid();
```

### İzin hatası:
RLS (Row Level Security) politikalarını kontrol edin ve gerekiyorsa geçici olarak devre dışı bırakın.

---

**Not:** Bu komutları Supabase Dashboard > SQL Editor'da çalıştırın. İlk defa admin rolü atadıktan sonra Flutter uygulamasını yeniden başlatın.
