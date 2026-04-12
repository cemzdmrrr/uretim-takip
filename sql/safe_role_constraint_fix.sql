-- Güvenli rol constraint güncellemesi
-- Önce mevcut rolleri kontrol et, sonra güncelle

-- 1. Mevcut rolleri göster
SELECT 'Mevcut roller:' as info;
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi 
FROM user_roles 
WHERE role IS NOT NULL 
GROUP BY role 
ORDER BY role;

-- 2. Problemli rolleri kontrol et
SELECT 'Problemli roller (yeni constraint dışında):' as info;
SELECT DISTINCT role 
FROM user_roles 
WHERE role IS NOT NULL 
AND role NOT IN (
    'admin', 'user', 'ik', 'personel', 'dokuma_firmasi',
    'konfeksiyon_firmasi', 'nakis_firmasi', 'yikama_firmasi',
    'utu_firmasi', 'ilik_dugme_firmasi', 'kalite_guvence',
    'sevkiyat_personeli', 'muhasebe', 'satis', 'tasarim',
    'planlama', 'depo'
);

-- 3. Problemli rolleri standart rollere dönüştür
DO $$
BEGIN
    -- Ortak rol eşleştirmeleri
    UPDATE user_roles SET role = 'user' WHERE role IN ('kullanici', 'normal_kullanici');
    UPDATE user_roles SET role = 'personel' WHERE role IN ('calisan', 'işçi', 'worker');
    UPDATE user_roles SET role = 'admin' WHERE role IN ('yonetici', 'administrator');
    UPDATE user_roles SET role = 'muhasebe' WHERE role IN ('mali_isler', 'finans');
    UPDATE user_roles SET role = 'depo' WHERE role IN ('depo_personeli', 'warehouse');
    
    -- Firma türü rolleri
    UPDATE user_roles SET role = 'dokuma_firmasi' WHERE role IN ('dokuma', 'örgü_firmasi', 'orgu_firmasi');
    UPDATE user_roles SET role = 'konfeksiyon_firmasi' WHERE role IN ('konfeksiyon', 'dikim');
    UPDATE user_roles SET role = 'nakis_firmasi' WHERE role IN ('nakış', 'nakis');
    UPDATE user_roles SET role = 'yikama_firmasi' WHERE role IN ('yıkama', 'yikama');
    UPDATE user_roles SET role = 'utu_firmasi' WHERE role IN ('ütü', 'utu', 'press');
    UPDATE user_roles SET role = 'kalite_guvence' WHERE role IN ('kalite', 'quality', 'qa', 'qc');
    UPDATE user_roles SET role = 'sevkiyat_personeli' WHERE role IN ('sevkiyat', 'kargo', 'shipping');
    
    -- Bilinmeyen rolleri 'user' yap
    UPDATE user_roles SET role = 'user' 
    WHERE role IS NOT NULL 
    AND role NOT IN (
        'admin', 'user', 'ik', 'personel', 'dokuma_firmasi',
        'konfeksiyon_firmasi', 'nakis_firmasi', 'yikama_firmasi',
        'utu_firmasi', 'ilik_dugme_firmasi', 'kalite_guvence',
        'sevkiyat_personeli', 'muhasebe', 'satis', 'tasarim',
        'planlama', 'depo'
    );
    
    RAISE NOTICE 'Roller standartlaştırıldı';
END $$;

-- 4. Güncellenmiş rolleri kontrol et
SELECT 'Güncellenmiş roller:' as info;
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi 
FROM user_roles 
WHERE role IS NOT NULL 
GROUP BY role 
ORDER BY role;

-- 5. Şimdi güvenli şekilde constraint'i güncelle
DO $$
BEGIN
    -- Mevcut constraint'i kaldır
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_roles' AND constraint_name = 'user_roles_role_check'
    ) THEN
        ALTER TABLE user_roles DROP CONSTRAINT user_roles_role_check;
        RAISE NOTICE 'Eski constraint kaldırıldı';
    END IF;

    -- Yeni constraint ekle
    ALTER TABLE user_roles 
    ADD CONSTRAINT user_roles_role_check 
    CHECK (role IN (
        'admin',                   -- Admin kullanıcı (atamaları yapan)
        'user',                    -- Normal kullanıcı
        'ik',                      -- İK
        'personel',                -- Genel personel
        'dokuma_firmasi',          -- Dokuma firma kullanıcısı (örgü aşaması)
        'konfeksiyon_firmasi',     -- Konfeksiyon firma kullanıcısı
        'nakis_firmasi',           -- Nakış firma kullanıcısı
        'yikama_firmasi',          -- Yıkama firma kullanıcısı
        'utu_firmasi',             -- Ütü firma kullanıcısı
        'ilik_dugme_firmasi',      -- İlik düğme firma kullanıcısı
        'kalite_guvence',          -- Kalite güvence personeli
        'sevkiyat_personeli',      -- Sevkiyat personeli
        'muhasebe',                -- Muhasebe
        'satis',                   -- Satış
        'tasarim',                 -- Tasarım
        'planlama',                -- Planlama
        'depo'                     -- Depo
    ));

    RAISE NOTICE '✓ Yeni constraint başarıyla eklendi';
END $$;

-- 6. Final kontrol
SELECT 'Final kontrol - tüm roller valid:' as info;
SELECT DISTINCT role, COUNT(*) as kullanici_sayisi 
FROM user_roles 
WHERE role IS NOT NULL 
GROUP BY role 
ORDER BY role;

SELECT 'Constraint güncelleme tamamlandı!' as sonuc;