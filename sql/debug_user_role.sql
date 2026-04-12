-- Kullanıcı rol durumunu kontrol et
-- Bu kodu Supabase SQL Editor'da çalıştırın

-- 1. Mevcut oturumdaki kullanıcı bilgisi
SELECT 
    'MEVCUT OTURUM BİLGİSİ' as kontrol_tipi,
    auth.uid() as user_id,
    u.email,
    u.created_at
FROM auth.users u 
WHERE u.id = auth.uid();

-- 2. user_roles tablosundaki durum
SELECT 
    'USER_ROLES TABLOSU' as kontrol_tipi,
    ur.user_id,
    ur.role,
    ur.aktif,
    ur.created_at,
    ur.updated_at
FROM public.user_roles ur
WHERE ur.user_id = auth.uid();

-- 3. is_admin() fonksiyon testi
SELECT 
    'FONKSİYON TESTİ' as kontrol_tipi,
    public.is_admin() as admin_mi;

-- 4. Tüm admin kullanıcıları göster
SELECT 
    'TÜM ADMİN KULLANICILAR' as kontrol_tipi,
    u.email,
    ur.role,
    ur.aktif,
    ur.updated_at
FROM auth.users u
JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;

-- 5. Eğer kullanıcı user_roles'de yoksa ekle
INSERT INTO public.user_roles (user_id, role, aktif)
SELECT auth.uid(), 'admin', true
WHERE NOT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = auth.uid()
)
RETURNING 'KULLANICI EKLENDİ' as durum, user_id, role;

-- 6. Kullanıcıyı kesinlikle admin yap (FORCE UPDATE)
UPDATE public.user_roles 
SET 
    role = 'admin',
    aktif = true,
    updated_at = now()
WHERE user_id = auth.uid()
RETURNING 'KULLANICI GÜNCELLENDİ' as durum, user_id, role, updated_at;