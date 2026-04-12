-- HEMEN KULLANICIYI ADMİN YAP - RLS KAPALI
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. user_roles RLS'ini kapat
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Kullanıcıyı zorla admin yap
DELETE FROM public.user_roles WHERE user_id = '72049fae-1bfa-43ae-9669-9586348e1431';

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES ('72049fae-1bfa-43ae-9669-9586348e1431', 'admin', true, now(), now());

-- 3. Kontrol et
SELECT 
    'KULLANICI ADMİN YAPILDI' as durum,
    u.email,
    ur.role,
    ur.aktif,
    'RLS KAPALI - ÇALIŞACAK' as not
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 4. RLS durumunu göster
SELECT 
    'user_roles RLS DURUMU' as tip,
    tablename,
    rowsecurity as rls_aktif
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'user_roles';