-- RLS Tamamen Devre Dışı - Admin Sorunu Kesin Çözüm
-- Bu script tüm RLS politikalarını kapatır ve admin sistemi için temiz bir başlangıç yapar

-- 1. Önce tüm mevcut politikaları sil
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      policy_record.policyname, 
                      policy_record.schemaname, 
                      policy_record.tablename);
        RAISE NOTICE 'Politika silindi: %.%.%', 
                     policy_record.schemaname, 
                     policy_record.tablename, 
                     policy_record.policyname;
    END LOOP;
END $$;

-- 2. Tüm tabloların RLS'ini kapat
ALTER TABLE IF EXISTS public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.modeller DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tedarikciler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.faturalar DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fatura_kalemleri DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hesaplari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hareketleri DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dosyalar DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sistem_ayarlari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.donemler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel_donem DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.aksesuarlar DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.iplik_siparisler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dokuma_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.izinler DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.mesailer DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bordro DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.odemeler DISABLE ROW LEVEL SECURITY;

-- 3. Auth fonksiyonlarını temizle
DROP FUNCTION IF EXISTS auth.is_admin();
DROP FUNCTION IF EXISTS public.is_admin_user();

-- 4. Basit bir admin kontrol fonksiyonu oluştur (public schema'da)
CREATE OR REPLACE FUNCTION public.check_admin(user_uuid UUID DEFAULT auth.uid())
RETURNS boolean AS $$
BEGIN
    -- Basit admin kontrolü
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = user_uuid 
        AND role = 'admin' 
        AND aktif = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Admin kullanıcı oluştur (eğer yoksa)
DO $$
DECLARE
    first_user_id UUID;
BEGIN
    -- İlk kullanıcıyı bul
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- Bu kullanıcıyı admin yap
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (first_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true,
            guncelleme_tarihi = NOW();
            
        RAISE NOTICE 'Admin kullanıcı oluşturuldu: %', first_user_id;
    ELSE
        RAISE NOTICE 'Henüz kullanıcı yok';
    END IF;
END $$;

-- 6. Sonuç kontrolü
SELECT 
    'RLS tamamen devre dışı bırakıldı!' as durum,
    COUNT(*) as kalan_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 7. Admin kullanıcıları listele
SELECT 
    ur.user_id,
    ur.role,
    ur.aktif,
    u.email,
    'Admin kullanıcı' as yetki
FROM public.user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'admin' AND ur.aktif = true;

-- 8. Test admin fonksiyonu
SELECT 
    public.check_admin() as mevcut_kullanici_admin_mi,
    'Admin kontrol fonksiyonu çalışıyor' as test_sonucu;
