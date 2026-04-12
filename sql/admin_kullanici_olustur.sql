-- Admin Kullanıcı Test ve Oluştur
-- Bu script kullanıcıyı admin yapar ve kontrol eder

-- 1. Mevcut durumu kontrol et
SELECT 
    'Mevcut kullanıcılar' as test_turu,
    u.id,
    u.email,
    ur.role,
    ur.aktif
FROM auth.users u
LEFT JOIN public.user_roles ur ON u.id = ur.user_id
ORDER BY u.created_at;

-- 2. İlk kullanıcıyı admin yap
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
        INSERT INTO public.user_roles (user_id, role, aktif, olusturma_tarihi)
        VALUES (current_user_id, 'admin', true, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true,
            guncelleme_tarihi = NOW();
            
        RAISE NOTICE 'Mevcut kullanıcı admin yapıldı: %', current_user_id;
    END IF;
    
    -- İlk kullanıcıyı da admin yap (farklıysa)
    IF first_user_id IS NOT NULL AND first_user_id != current_user_id THEN
        INSERT INTO public.user_roles (user_id, role, aktif, olusturma_tarihi)
        VALUES (first_user_id, 'admin', true, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true,
            guncelleme_tarihi = NOW();
            
        RAISE NOTICE 'İlk kullanıcı admin yapıldı: %', first_user_id;
    END IF;
    
    -- Hiç kullanıcı yoksa uyarı ver
    IF first_user_id IS NULL THEN
        RAISE NOTICE 'Henüz hiç kullanıcı yok. Önce sisteme giriş yapın.';
    END IF;
END $$;

-- 3. Sonuç kontrolü
SELECT 
    'Admin kullanıcılar' as test_turu,
    u.id,
    u.email,
    ur.role,
    ur.aktif,
    ur.olusturma_tarihi
FROM auth.users u
INNER JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true
ORDER BY ur.olusturma_tarihi;

-- 4. user_roles tablosu durumu
SELECT 
    'Tüm roller' as test_turu,
    COUNT(*) as toplam_kayit,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_sayisi,
    COUNT(CASE WHEN aktif = true THEN 1 END) as aktif_sayisi
FROM public.user_roles;

-- 5. Mevcut oturumu kontrol et
SELECT 
    'Mevcut oturum' as test_turu,
    auth.uid() as oturum_user_id,
    (SELECT role FROM public.user_roles WHERE user_id = auth.uid()) as oturum_rol;
