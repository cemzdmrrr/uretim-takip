-- Mevcut kullanıcıyı admin yap
-- Bu komutu Supabase SQL Editor'da çalıştırın

-- 1. Önce mevcut kullanıcı ID'sini bulun
SELECT 
    'Mevcut kullanıcı bilgileri' as tip,
    auth.uid() as user_id,
    u.email
FROM auth.users u 
WHERE u.id = auth.uid();

-- 2. Kullanıcıyı admin yapın
INSERT INTO public.user_roles (user_id, role, aktif)
VALUES (auth.uid(), 'admin', true)
ON CONFLICT (user_id) 
DO UPDATE SET 
    role = 'admin',
    aktif = true,
    updated_at = now();

-- 3. Sonucu kontrol edin
SELECT 
    'Güncellenmiş rol bilgisi' as tip,
    u.email,
    ur.role,
    ur.aktif,
    ur.updated_at
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.id = auth.uid();