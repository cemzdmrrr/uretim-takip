-- Kalite kontrol personeli test kullanıcısı oluştur

-- Önce auth.users tablosuna kullanıcı ekle (gerçek uygulamada Supabase Auth aracılığıyla yapılmalı)
-- Bu sadece test amaçlıdır

-- Test kalite personeli için user_roles kaydı oluştur
-- Önce mevcut test kullanıcısını kontrol et
DO $$
DECLARE
    test_user_id uuid;
BEGIN
    -- Test kullanıcısı var mı kontrol et (email ile)
    SELECT id INTO test_user_id 
    FROM auth.users 
    WHERE email = 'kalite@test.com' 
    LIMIT 1;
    
    -- Eğer kullanıcı varsa, kalite_kontrol rolünü ekle
    IF test_user_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role, created_at)
        VALUES (test_user_id, 'kalite_kontrol', NOW())
        ON CONFLICT (user_id, role) DO NOTHING;
        
        RAISE NOTICE 'Kalite kontrol rolü eklendi: %', test_user_id;
    ELSE
        RAISE NOTICE 'Test kullanıcısı bulunamadı: kalite@test.com';
    END IF;
END $$;

-- Admin kullanıcısına da kalite_kontrol rolü ver (test için)
DO $$
DECLARE
    admin_user_id uuid;
BEGIN
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'admin@admin.com' 
    LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        INSERT INTO user_roles (user_id, role, created_at)
        VALUES (admin_user_id, 'kalite_kontrol', NOW())
        ON CONFLICT (user_id, role) DO NOTHING;
        
        RAISE NOTICE 'Admin kullanıcısına kalite kontrol rolü eklendi: %', admin_user_id;
    ELSE
        RAISE NOTICE 'Admin kullanıcısı bulunamadı';
    END IF;
END $$;

-- Mevcut user_roles kayıtlarını kontrol et
SELECT 
    u.email,
    ur.role,
    ur.created_at
FROM user_roles ur
JOIN auth.users u ON u.id = ur.user_id
ORDER BY ur.created_at DESC;