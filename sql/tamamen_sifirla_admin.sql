-- TAMAMEN SIFIRLA VE BAŞTAN YAZ
-- Tüm RLS'i kaldır, admin sistemi basit olsun

-- 1. Tüm politikaları tamamen sil
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Önce tüm politikaları listele ve sil
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY %I ON %I.%I', 
                          policy_record.policyname, 
                          policy_record.schemaname, 
                          policy_record.tablename);
            RAISE NOTICE 'Politika silindi: %.%.%', 
                         policy_record.schemaname, 
                         policy_record.tablename, 
                         policy_record.policyname;
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'Politika silme hatası: %.%.% - %', 
                             policy_record.schemaname, 
                             policy_record.tablename, 
                             policy_record.policyname,
                             SQLERRM;
        END;
    END LOOP;
END $$;

-- 2. Tüm tabloların RLS'ini tamamen kapat
DO $$
DECLARE
    tablo_record RECORD;
BEGIN
    FOR tablo_record IN 
        SELECT tablename
        FROM pg_tables 
        WHERE schemaname = 'public'
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
        AND tablename NOT LIKE '_realtime_%'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', tablo_record.tablename);
            RAISE NOTICE 'RLS kapatıldı: %', tablo_record.tablename;
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'RLS kapatma hatası: % - %', tablo_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. Eski admin fonksiyonlarını temizle
DROP FUNCTION IF EXISTS public.is_admin_user();
DROP FUNCTION IF EXISTS public.admin_kontrol();
DROP FUNCTION IF EXISTS public.check_admin();
DROP FUNCTION IF EXISTS auth.is_admin();

-- 4. Yeni basit admin fonksiyonu (RLS kullanmayan)
CREATE OR REPLACE FUNCTION public.basit_admin_kontrol(kullanici_id UUID DEFAULT auth.uid())
RETURNS boolean AS $$
BEGIN
    -- Direkt sorgu, RLS yok
    IF kullanici_id IS NULL THEN
        RETURN false;
    END IF;
    
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = kullanici_id 
        AND role = 'admin' 
        AND aktif = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. user_roles tablosunu temizle ve yeniden düzenle
-- Önce mevcut kayıtları kontrol et
SELECT 
    'Mevcut user_roles kayıtları' as durum,
    COUNT(*) as toplam_kayit,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_sayisi
FROM public.user_roles;

-- 6. İlk kullanıcıyı admin yap
DO $$
DECLARE
    first_user_id UUID;
    mevcut_kullanici UUID;
BEGIN
    -- Mevcut oturum kullanıcısı
    mevcut_kullanici := auth.uid();
    
    -- İlk kayıtlı kullanıcı
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    -- Mevcut kullanıcıyı admin yap
    IF mevcut_kullanici IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (mevcut_kullanici, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
        RAISE NOTICE 'Mevcut kullanıcı admin yapıldı: %', mevcut_kullanici;
    END IF;
    
    -- İlk kullanıcıyı da admin yap (farklıysa)
    IF first_user_id IS NOT NULL AND (mevcut_kullanici IS NULL OR first_user_id != mevcut_kullanici) THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (first_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
        RAISE NOTICE 'İlk kullanıcı admin yapıldı: %', first_user_id;
    END IF;
    
    -- Eğer hiç kullanıcı yoksa uyarı
    IF first_user_id IS NULL THEN
        RAISE NOTICE 'Henüz hiç kullanıcı yok. Sisteme giriş yapın.';
    END IF;
END $$;

-- 7. Son durum kontrolü
SELECT 
    'RLS tamamen temizlendi!' as durum,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as kalan_politika,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) as rls_aktif_tablo
;

-- 8. Admin fonksiyon test
SELECT 
    'Admin fonksiyon test' as test_turu,
    public.basit_admin_kontrol() as admin_mi,
    auth.uid() as kullanici_id;

-- 9. Tüm admin kullanıcıları göster
SELECT 
    'Admin Kullanıcılar' as tip,
    u.id,
    u.email,
    ur.role,
    ur.aktif,
    public.basit_admin_kontrol(u.id) as admin_fonksiyon_sonucu
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true
ORDER BY u.created_at;

-- 10. Tablolar ve RLS durumu
SELECT 
    'Tablo RLS Durumu' as tip,
    tablename,
    rowsecurity as rls_aktif_mi
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('user_roles', 'modeller', 'personel', 'tedarikciler', 'faturalar')
ORDER BY tablename;
