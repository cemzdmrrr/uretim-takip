-- Admin Kullanıcı Kurulumu ve Yetkilendirme
-- Bu dosyayı çalıştırarak mevcut kullanıcıyı admin yapın

-- 1. Mevcut kullanıcıyı admin yap
INSERT INTO user_roles (user_id, role, yetki_seviyesi)
VALUES (auth.uid(), 'admin', 'admin')
ON CONFLICT (user_id) DO UPDATE SET 
    role = 'admin',
    yetki_seviyesi = 'admin';

-- 2. Admin için tüm RLS politikalarını esnek hale getir
-- user_roles tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm user_roles verilerine erişebilir" ON user_roles;
CREATE POLICY "Admin tüm user_roles verilerine erişebilir" ON user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- triko_takip tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm triko_takip verilerine erişebilir" ON triko_takip;
CREATE POLICY "Admin tüm triko_takip verilerine erişebilir" ON triko_takip
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- sevk_talepleri tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm sevk_talepleri verilerine erişebilir" ON sevk_talepleri;
CREATE POLICY "Admin tüm sevk_talepleri verilerine erişebilir" ON sevk_talepleri
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- uretim_kayitlari tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm uretim_kayitlari verilerine erişebilir" ON uretim_kayitlari;
CREATE POLICY "Admin tüm uretim_kayitlari verilerine erişebilir" ON uretim_kayitlari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- atolyeler tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm atolyeler verilerine erişebilir" ON atolyeler;
CREATE POLICY "Admin tüm atolyeler verilerine erişebilir" ON atolyeler
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- bildirimler tablosu için admin politikaları (eğer varsa)
DROP POLICY IF EXISTS "Admin tüm bildirimler verilerine erişebilir" ON bildirimler;
CREATE POLICY "Admin tüm bildirimler verilerine erişebilir" ON bildirimler
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- 3. Bildirimler tablosunun yapısını kontrol et ve gerekirse oluştur
CREATE TABLE IF NOT EXISTS bildirimler (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    baslik TEXT NOT NULL,
    mesaj TEXT NOT NULL,
    tip VARCHAR(20) DEFAULT 'bilgi', -- 'bilgi', 'uyari', 'hata', 'basari'
    okundu BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bildirimler tablosu için RLS aktif et
ALTER TABLE bildirimler ENABLE ROW LEVEL SECURITY;

-- 4. Admin için demo bildirim oluştur
INSERT INTO bildirimler (user_id, baslik, mesaj, tip, okundu)
VALUES (
    auth.uid(),
    'Admin Panel Aktif',
    'Admin yetkileri başarıyla aktif edildi. Tüm sistem özelliklerine erişim sağlandı.',
    'basari',
    false
) ON CONFLICT DO NOTHING;

-- 5. Admin yetkilerini test et
DO $$
DECLARE
    user_count INTEGER;
    model_count INTEGER;
    sevk_count INTEGER;
BEGIN
    -- Kullanıcı sayısını say
    SELECT COUNT(*) INTO user_count FROM user_roles;
    
    -- Model sayısını say
    SELECT COUNT(*) INTO model_count FROM triko_takip;
    
    -- Sevkiyat talebi sayısını say
    SELECT COUNT(*) INTO sevk_count FROM sevk_talepleri;
    
    RAISE NOTICE 'Admin Yetki Testi Sonuçları:';
    RAISE NOTICE 'Toplam Kullanıcı: %', user_count;
    RAISE NOTICE 'Toplam Model: %', model_count;
    RAISE NOTICE 'Toplam Sevk Talebi: %', sevk_count;
    
    IF user_count > 0 THEN
        RAISE NOTICE '✓ user_roles tablosuna erişim başarılı';
    ELSE
        RAISE NOTICE '✗ user_roles tablosuna erişim başarısız';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test sırasında hata: %', SQLERRM;
END $$;

-- 6. Mevcut kullanıcının admin durumunu doğrula
SELECT 
    u.email,
    ur.role,
    ur.yetki_seviyesi,
    'Admin yetkileri aktif' as durum
FROM auth.users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE u.id = auth.uid();

RAISE NOTICE 'Admin kurulumu tamamlandı! Artık tüm sistem yetkileriniz aktif.';
