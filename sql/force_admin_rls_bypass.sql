-- KULLANICI ADMİN YAPMA KOMUTU - RLS BYPASS
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. RLS'i geçici olarak devre dışı bırak (sadece bu oturum için)
SET row_security = off;

-- 2. Mevcut kullanıcının bilgilerini gör
SELECT 
    'MEVCUT KULLANICI' as tip,
    id,
    email,
    created_at
FROM auth.users 
WHERE id = auth.uid();

-- 3. user_roles tablosundaki durumu kontrol et
SELECT 
    'MEVCUT USER_ROLES' as tip,
    user_id,
    role,
    aktif
FROM public.user_roles 
WHERE user_id = auth.uid();

-- 4. Kullanıcıyı zorla admin yap (RLS bypass)
DELETE FROM public.user_roles WHERE user_id = auth.uid();

INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES (auth.uid(), 'admin', true, now(), now());

-- 5. Kontrol et
SELECT 
    'SON DURUM' as tip,
    u.email,
    ur.role,
    ur.aktif,
    ur.updated_at
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = auth.uid();

-- 6. RLS'i tekrar aç
SET row_security = on;