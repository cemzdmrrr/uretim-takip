-- TAMAMEN BASİT ÇÖZÜM - RLS YOK
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. user_roles tablosunun RLS'ini tamamen kapat
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Tüm politikaları sil
DO $$
DECLARE
    policy_name TEXT;
BEGIN
    FOR policy_name IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'user_roles'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY %I ON public.user_roles', policy_name);
            RAISE NOTICE 'Politika silindi: %', policy_name;
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'Politika silme hatası: % - %', policy_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. Belirli kullanıcıyı admin yap
DELETE FROM public.user_roles 
WHERE user_id = '72049fae-1bfa-43ae-9669-9586348e1431';

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES ('72049fae-1bfa-43ae-9669-9586348e1431', 'admin', true, now(), now());

-- 4. Sonucu kontrol et
SELECT 
    'BAŞARILI - RLS KAPALI' as durum,
    u.email,
    u.id as user_id,
    ur.role,
    ur.aktif,
    'user_roles artık RLS-free' as not
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 5. Tüm kullanıcı rollerini göster
SELECT 
    'TÜM KULLANICI ROLLERİ' as tip,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
ORDER BY ur.role DESC;