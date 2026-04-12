-- GÜVENLİ ROLLER GÜNCELLEMESİ - ADIM ADIM

-- ADIM 1: Mevcut durumu kontrol et
SELECT 'MEVCUT ROLLER' as baslik, role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- ADIM 2: Problemli rolleri tespit et
SELECT 'PROBLEMLİ ROLLER' as baslik, role
FROM (
    SELECT DISTINCT role
    FROM user_roles 
    WHERE role NOT IN (
        'admin', 'user', 'ik', 'personel', 'orgu_firmasi', 'dokuma',
        'konfeksiyon', 'yikama', 'utu', 'ilik_dugme', 'kalite_kontrol',
        'paketleme', 'sevkiyat', 'muhasebe', 'satis', 'tasarim', 'planlama', 'depo'
    )
) as problemli_roller;

-- ADIM 3: Her problematik rol için önerilen güncelleme
-- Bu kısmı manuel olarak çalıştırın, her satırı ayrı ayrı:

-- Önce constraint'i kaldır (geçici olarak)
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_check;

-- Eski rolleri yeni rollere güncelle (tek tek çalıştırın):
-- UPDATE user_roles SET role = 'konfeksiyon' WHERE role = 'tekstil';
-- UPDATE user_roles SET role = 'dokuma' WHERE role = 'orgu';  
-- UPDATE user_roles SET role = 'utu' WHERE role = 'utu_paket';
-- UPDATE user_roles SET role = 'sevkiyat' WHERE role = 'sevkiyat_soforu';
-- UPDATE user_roles SET role = 'kalite_kontrol' WHERE role = 'kalite_personeli';
-- UPDATE user_roles SET role = 'konfeksiyon' WHERE role = 'atolye_personeli';
-- UPDATE user_roles SET role = 'tasarim' WHERE role = 'nakis';
-- UPDATE user_roles SET role = 'depo' WHERE role = 'iplik';
-- UPDATE user_roles SET role = 'paketleme' WHERE role = 'ambalaj';
-- UPDATE user_roles SET role = 'sevkiyat' WHERE role = 'lojistik';
-- UPDATE user_roles SET role = 'depo' WHERE role = 'aksesuar';
-- UPDATE user_roles SET role = 'depo' WHERE role = 'makine';
-- UPDATE user_roles SET role = 'depo' WHERE role = 'kimyasal';
-- UPDATE user_roles SET role = 'user' WHERE role = 'diger';

-- ADIM 4: Güncellemeden sonra kontrol et
SELECT 'GÜNCELLENME SONRASI' as baslik, role, COUNT(*) as kullanici_sayisi
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- ADIM 5: Hala problemli rol var mı kontrol et  
SELECT 'KALAN PROBLEMLİ ROLLER' as baslik, role
FROM (
    SELECT DISTINCT role
    FROM user_roles 
    WHERE role NOT IN (
        'admin', 'user', 'ik', 'personel', 'orgu_firmasi', 'dokuma',
        'konfeksiyon', 'yikama', 'utu', 'ilik_dugme', 'kalite_kontrol',
        'paketleme', 'sevkiyat', 'muhasebe', 'satis', 'tasarim', 'planlama', 'depo'
    )
) as problemli_roller;

-- ADIM 6: Tüm roller temizse constraint'i ekle
-- Bu komutu sadece yukarıdaki kontroller temizse çalıştırın:
-- ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_check 
-- CHECK (role IN (
--     'admin', 'user', 'ik', 'personel', 'orgu_firmasi', 'dokuma',
--     'konfeksiyon', 'yikama', 'utu', 'ilik_dugme', 'kalite_kontrol',
--     'paketleme', 'sevkiyat', 'muhasebe', 'satis', 'tasarim', 'planlama', 'depo'
-- ));

-- ADIM 7: Final kontrol
-- SELECT 'FİNAL DURUM' as baslik, role, COUNT(*) as kullanici_sayisi
-- FROM user_roles 
-- GROUP BY role 
-- ORDER BY role;
