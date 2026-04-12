-- Email adresi ile kullanıcıyı admin yap
-- 'YOUR_EMAIL@DOMAIN.COM' kısmını kendi email adresinizle değiştirin

-- 1. Email ile kullanıcı ID'sini bul ve admin yap
INSERT INTO public.user_roles (user_id, role, aktif)
SELECT 
    u.id,
    'admin'::character varying,
    true
FROM auth.users u 
WHERE u.email = 'YOUR_EMAIL@DOMAIN.COM'  -- Buraya kendi email'inizi yazın
ON CONFLICT (user_id) 
DO UPDATE SET 
    role = 'admin',
    aktif = true,
    updated_at = now();

-- 2. Sonucu kontrol et
SELECT 
    'Admin yapıldı' as durum,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE u.email = 'YOUR_EMAIL@DOMAIN.COM';  -- Buraya kendi email'inizi yazın