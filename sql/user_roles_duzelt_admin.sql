-- user_roles TABLOSUNU DÜZELTİP ADMIN SİSTEMİNİ KURALIM
-- Önce constraint hatası, sonra admin sistemi

-- 1. user_roles tablosuna unique constraint ekle
ALTER TABLE public.user_roles 
ADD CONSTRAINT user_roles_user_id_unique UNIQUE (user_id);

-- 2. Tüm politikaları tamamen sil
DO $$
DECLARE
    policy_record RECORD;
BEGIN
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

-- 3. Tüm tabloların RLS'ini tamamen kapat
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

-- 4. Eski admin fonksiyonlarını temizle
DROP FUNCTION IF EXISTS public.is_admin_user();
DROP FUNCTION IF EXISTS public.admin_kontrol();
DROP FUNCTION IF EXISTS public.check_admin();
DROP FUNCTION IF EXISTS auth.is_admin();

-- 5. Yeni basit admin fonksiyonu
CREATE OR REPLACE FUNCTION public.basit_admin_kontrol(kullanici_id UUID DEFAULT auth.uid())
RETURNS boolean AS $$
BEGIN
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

-- 6. Çift kayıt varsa temizle (unique constraint öncesi)
DELETE FROM public.user_roles ur1
WHERE EXISTS (
    SELECT 1 
    FROM public.user_roles ur2 
    WHERE ur2.user_id = ur1.user_id 
    AND ur2.id > ur1.id
);

-- 7. İlk kullanıcıyı admin yap
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

-- 8. Final kontroller
SELECT 
    'user_roles tablosu düzeltildi!' as durum,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as kalan_politika,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) as rls_aktif_tablo,
    (SELECT COUNT(*) FROM public.user_roles WHERE role = 'admin') as admin_sayisi;

-- 9. Admin test
SELECT 
    'Admin Test' as test,
    public.basit_admin_kontrol() as admin_mi,
    auth.uid() as mevcut_kullanici;

-- 10. Tüm admin kullanıcıları
SELECT 
    'Admin Kullanıcılar' as tip,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
INNER JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;
