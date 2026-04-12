-- İlk kayıt olan kullanıcıyı admin yap

INSERT INTO public.user_roles (user_id, role, aktif)
SELECT 
    id,
    'admin'::character varying,
    true
FROM auth.users 
ORDER BY created_at 
LIMIT 1
ON CONFLICT (user_id) 
DO UPDATE SET 
    role = 'admin',
    aktif = true,
    updated_at = now();

-- Sonucu göster
SELECT 
    'İlk kullanıcı admin yapıldı' as durum,
    u.email,
    u.created_at,
    ur.role
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin'
ORDER BY u.created_at
LIMIT 1;