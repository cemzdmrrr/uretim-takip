-- BELİRLİ KULLANICIYI ADMİN YAP - BASİT VERSİYON
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. user_roles tablosunun RLS'ini tamamen kapat
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;

-- 2. Kullanıcı ID: 72049fae-1bfa-43ae-9669-9586348e1431
-- Önce varolan kaydı sil
DELETE FROM public.user_roles 
WHERE user_id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 3. Admin olarak ekle
INSERT INTO public.user_roles (user_id, role, aktif, created_at, updated_at)
VALUES ('72049fae-1bfa-43ae-9669-9586348e1431', 'admin', true, now(), now());

-- 4. Kontrol et
SELECT 
    'KULLANICI ADMİN YAPILDI' as durum,
    u.email,
    u.id as user_id,
    ur.role,
    ur.aktif,
    ur.created_at
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = '72049fae-1bfa-43ae-9669-9586348e1431';

-- 5. Tüm admin kullanıcıları göster
SELECT 
    'TÜM ADMİN KULLANICILAR' as tip,
    u.email,
    u.id,
    ur.role,
    ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;