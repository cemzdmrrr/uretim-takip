-- Problemli constraint durumunu düzeltme scripti
-- Önce mevcut durumu kontrol edip sonra temizleme yapacağız

-- 1. Mevcut constraint durumunu kontrol et
DO $$
DECLARE
    constraint_exists BOOLEAN;
BEGIN
    -- Constraint var mı kontrol et
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_roles' AND constraint_name = 'user_roles_role_check'
    ) INTO constraint_exists;
    
    IF constraint_exists THEN
        RAISE NOTICE 'Mevcut constraint bulundu, kaldırılıyor...';
        ALTER TABLE user_roles DROP CONSTRAINT user_roles_role_check;
    ELSE
        RAISE NOTICE 'Constraint zaten yok';
    END IF;
END $$;

-- 2. Mevcut rolleri göster
SELECT 'Mevcut roller:' as durum, role, COUNT(*) as adet 
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- 3. Güvenli rol güncellemesi yap
DO $$
BEGIN
    -- Problematic olmayan güncellemeler önce
    UPDATE user_roles SET role = 'user' WHERE role IN ('kullanici', 'normal_kullanici');
    UPDATE user_roles SET role = 'admin' WHERE role IN ('yonetici', 'administrator');
    UPDATE user_roles SET role = 'personel' WHERE role IN ('calisan', 'işçi', 'worker');
    
    RAISE NOTICE 'Temel roller güncellendi';
END $$;

-- 4. Yeni constraint'i sadece temel rollerle ekle (geçici)
ALTER TABLE user_roles 
ADD CONSTRAINT user_roles_role_check_temp
CHECK (role IN ('admin', 'user', 'ik', 'personel'));

-- 5. Firma rollerini aşamalı olarak güncelle
DO $$
BEGIN
    -- Önce constraint'i kaldır
    ALTER TABLE user_roles DROP CONSTRAINT user_roles_role_check_temp;
    
    -- Firma rollerini tek tek güncelle
    UPDATE user_roles SET role = 'user' WHERE role IN ('dokuma', 'örgü_firmasi', 'orgu_firmasi');
    UPDATE user_roles SET role = 'user' WHERE role IN ('konfeksiyon', 'dikim');
    UPDATE user_roles SET role = 'user' WHERE role IN ('nakış', 'nakis');
    UPDATE user_roles SET role = 'user' WHERE role IN ('yıkama', 'yikama');
    UPDATE user_roles SET role = 'user' WHERE role IN ('ütü', 'utu', 'press');
    UPDATE user_roles SET role = 'user' WHERE role IN ('kalite', 'quality', 'qa', 'qc');
    UPDATE user_roles SET role = 'user' WHERE role IN ('sevkiyat', 'kargo', 'shipping');
    UPDATE user_roles SET role = 'user' WHERE role IN ('muhasebe', 'mali_isler', 'finans');
    UPDATE user_roles SET role = 'user' WHERE role IN ('depo_personeli', 'warehouse');
    
    -- Bilinmeyen rolleri de user yap
    UPDATE user_roles SET role = 'user' 
    WHERE role NOT IN ('admin', 'user', 'ik', 'personel');
    
    RAISE NOTICE 'Tüm roller user veya temel roller haline getirildi';
END $$;

-- 6. Final constraint'i ekle
ALTER TABLE user_roles 
ADD CONSTRAINT user_roles_role_check 
CHECK (role IN (
    'admin',                   -- Admin kullanıcı (atamaları yapan)
    'user',                    -- Normal kullanıcı (firma kullanıcıları dahil)
    'ik',                      -- İK
    'personel'                 -- Genel personel
));

-- 7. Şimdi workflow için gerekli ek tabloyu oluştur
-- Firma kullanıcıları için ayrı tablo
CREATE TABLE IF NOT EXISTS firma_kullanicilari (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    firma_id UUID REFERENCES atolyeler(id) ON DELETE CASCADE,
    firma_turu TEXT NOT NULL CHECK (firma_turu IN (
        'dokuma_firmasi',
        'konfeksiyon_firmasi', 
        'nakis_firmasi',
        'yikama_firmasi',
        'utu_firmasi',
        'ilik_dugme_firmasi'
    )),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, firma_id)
);

-- Kalite ve sevkiyat personeli için ayrı tablo  
CREATE TABLE IF NOT EXISTS ozel_personel (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    personel_turu TEXT NOT NULL CHECK (personel_turu IN (
        'kalite_guvence',
        'sevkiyat_personeli',
        'muhasebe',
        'satis',
        'tasarim', 
        'planlama',
        'depo'
    )),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, personel_turu)
);

-- 8. Güncellenmiş rolleri göster
SELECT 'Güncellenmiş roller:' as durum, role, COUNT(*) as adet 
FROM user_roles 
GROUP BY role 
ORDER BY role;

-- 9. İndexler
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_user_id ON firma_kullanicilari(user_id);
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_firma_id ON firma_kullanicilari(firma_id);
CREATE INDEX IF NOT EXISTS idx_ozel_personel_user_id ON ozel_personel(user_id);
CREATE INDEX IF NOT EXISTS idx_ozel_personel_turu ON ozel_personel(personel_turu);

SELECT 'Constraint problemi çözüldü! Firma kullanıcıları artık ayrı tabloda.' as sonuc;