-- Admin rolünü kontrol etmek ve sistemde admin kullanıcı yaratmak için script
-- Önce var olan bir kullanıcıyı admin yapalım

-- Admin user oluşturma (eğer yoksa)
DO $$
DECLARE
    test_user_id UUID;
    user_exists BOOLEAN;
BEGIN
    -- Herhangi bir kullanıcı var mı kontrol et
    SELECT EXISTS(SELECT 1 FROM auth.users LIMIT 1) INTO user_exists;
    
    IF user_exists THEN
        -- İlk kullanıcıyı admin yap
        SELECT id INTO test_user_id FROM auth.users LIMIT 1;
        
        -- User_roles tablosuna admin kaydı ekle veya güncelle
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (test_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true,
            guncelleme_tarihi = NOW();
            
        RAISE NOTICE 'Admin kullanıcı oluşturuldu/güncellendi: %', test_user_id;
    ELSE
        RAISE NOTICE 'Henüz hiç kullanıcı yok, önce kayıt olun';
    END IF;
END $$;

-- Admin politikalarını kontrol et
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE policyname LIKE '%admin%' OR policyname LIKE '%Admin%'
ORDER BY tablename, policyname;

-- Tüm user_roles kayıtlarını listele
SELECT 
    ur.user_id,
    ur.role,
    ur.aktif,
    u.email,
    ur.olusturma_tarihi
FROM public.user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
ORDER BY ur.olusturma_tarihi DESC;

SELECT 'Admin setup tamamlandı!' as message;
