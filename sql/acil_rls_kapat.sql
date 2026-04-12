-- ACİL ÇÖZÜM: RLS'i Tamamen Kapat
-- Bu infinite recursion hatasını kesin çözer

-- 1. Tüm politikaları sil
DROP POLICY IF EXISTS "user_roles_own_select" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_insert" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_update" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_admin_delete" ON public.user_roles;

-- 2. user_roles tablosunun RLS'ini tamamen kapat
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 3. Diğer tüm tabloların da RLS'ini kapat
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

-- 4. Tüm politikaları temizle
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
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
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

-- 5. İlk kullanıcıyı admin yap (RLS olmadan)
DO $$
DECLARE
    first_user_id UUID;
    current_user_id UUID;
BEGIN
    -- Mevcut oturum kullanıcısını al
    current_user_id := auth.uid();
    
    -- İlk kullanıcıyı al
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    -- Eğer oturum açık kullanıcı varsa onu admin yap
    IF current_user_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (current_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
            
        RAISE NOTICE 'Mevcut kullanıcı admin yapıldı: %', current_user_id;
    END IF;
    
    -- İlk kullanıcıyı da admin yap (farklıysa)
    IF first_user_id IS NOT NULL AND (current_user_id IS NULL OR first_user_id != current_user_id) THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (first_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
            
        RAISE NOTICE 'İlk kullanıcı admin yapıldı: %', first_user_id;
    END IF;
END $$;

-- 6. Sonuç kontrolü
SELECT 
    'RLS tamamen kapatıldı!' as durum,
    COUNT(*) as kalan_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 7. Admin kullanıcıları göster
SELECT 
    'Admin kullanıcılar' as tip,
    u.id,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
INNER JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;
