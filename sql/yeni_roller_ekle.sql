-- Yeni üretim aşaması rollerini user_roles constraint'ine ekle

-- Önce mevcut problemli rolleri kontrol et ve düzelt

-- 1. Mevcut rolleri listele
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- 2. Problemli rolleri tespit et
SELECT DISTINCT role
FROM user_roles 
WHERE role NOT IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
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
    'depo'
);

-- 3. Eski rolleri yeni rollere map et (güncelleme yapmadan önce kontrol edin)
-- Örnek güncellemeler (gerçek verilerinize göre ayarlayın):

-- Eski tekstil rollerini uygun departmanlara güncelle
UPDATE user_roles SET role = 'konfeksiyon' WHERE role = 'tekstil';
UPDATE user_roles SET role = 'dokuma' WHERE role = 'orgu';
UPDATE user_roles SET role = 'utu' WHERE role = 'utu_paket';
UPDATE user_roles SET role = 'sevkiyat' WHERE role = 'sevkiyat_soforu';
UPDATE user_roles SET role = 'kalite_kontrol' WHERE role = 'kalite_personeli';
UPDATE user_roles SET role = 'konfeksiyon' WHERE role = 'atolye_personeli';
UPDATE user_roles SET role = 'tasarim' WHERE role = 'nakis';
UPDATE user_roles SET role = 'depo' WHERE role = 'iplik';
UPDATE user_roles SET role = 'paketleme' WHERE role = 'ambalaj';
UPDATE user_roles SET role = 'sevkiyat' WHERE role = 'lojistik';
UPDATE user_roles SET role = 'depo' WHERE role = 'aksesuar';
UPDATE user_roles SET role = 'depo' WHERE role = 'makine';
UPDATE user_roles SET role = 'depo' WHERE role = 'kimyasal';
UPDATE user_roles SET role = 'user' WHERE role = 'diger';

-- 4. Güncellemeden sonra kontrol et
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- 5. Hala uyumsuz roller var mı kontrol et
SELECT DISTINCT role
FROM user_roles 
WHERE role NOT IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
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
    'depo'
);

-- 6. Önce mevcut constraint'i kaldır
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- 7. Yeni constraint'i tüm rollerle birlikte ekle
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check 
CHECK (role IN (
    'admin', 
    'user', 
    'ik', 
    'personel', 
    'orgu_firmasi', 
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
    'depo'
));

-- Kontrol sorgusu - mevcut roller
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;
