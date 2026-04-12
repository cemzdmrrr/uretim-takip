-- Sevkiyat rolünü user_roles tablosuna ekle
-- Bu script mevcut constraint'i günceller

-- 1. Mevcut constraint'i kaldır
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- 2. Yeni constraint'i tüm rollerle birlikte ekle
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check 
CHECK (role IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
    'tedarikci_dokuma',
    'tedarikci_yikama',
    'tedarikci_utu',
    'tedarikci_konfeksiyon',
    'tedarikci_aksesuar',
    'dokuma',
    'konfeksiyon',
    'yikama',
    'utu',
    'ilik_dugme',
    'kalite_kontrol',
    'paketleme',
    'sevkiyat',
    'muhasebe',
    'satis',
    'tasarim',
    'planlama',
    'depo',
    'sofor'
));

-- 3. Kontrol et - mevcut rolleri listele
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- 4. Constraint'i kontrol et
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'user_roles_role_check';
