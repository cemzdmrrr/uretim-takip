-- TAMAMEN RLS'SİZ ÇÖZÜM
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
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_roles', policy_name);
    END LOOP;
END $$;

-- 3. Kullanıcıyı admin yap
DELETE FROM public.user_roles WHERE user_id = auth.uid();

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES (auth.uid(), 'admin', true, now(), now());

-- 4. Sonucu kontrol et
SELECT 
    'RLS KAPALI - ADMİN YAPILDI' as durum,
    u.email,
    ur.role,
    ur.aktif,
    'user_roles tablosu artık RLS-free' as not
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = auth.uid();