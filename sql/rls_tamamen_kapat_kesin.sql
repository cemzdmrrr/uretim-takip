-- KESIN ÇÖZÜM: RLS'i Tamamen Kapat ve Admin Sistemi Çalıştır
-- Bu script infinite recursion sorununu tamamen çözer

-- 1. Tüm politikaları sil
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      policy_record.policyname, 
                      policy_record.schemaname, 
                      policy_record.tablename);
        RAISE NOTICE 'Politika silindi: %.%.%', 
                     policy_record.schemaname, 
                     policy_record.tablename, 
                     policy_record.policyname;
    END LOOP;
END $$;

-- 2. Tüm tabloların RLS'ini tamamen kapat
DO $$
DECLARE
    tablo_record RECORD;
BEGIN
    FOR tablo_record IN 
        SELECT tablename
        FROM pg_tables 
        WHERE schemaname = 'public'
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', tablo_record.tablename);
            RAISE NOTICE 'RLS kapatıldı: %', tablo_record.tablename;
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'RLS kapatma hatası: % - %', tablo_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. Admin kontrol fonksiyonu oluştur (RLS olmadan)
CREATE OR REPLACE FUNCTION public.admin_kontrol(user_uuid UUID DEFAULT auth.uid())
RETURNS boolean AS $$
BEGIN
    -- Basit admin kontrolü - RLS yok
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = user_uuid 
        AND role = 'admin' 
        AND aktif = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. İlk kullanıcıyı admin yap
DO $$
DECLARE
    first_user_id UUID;
BEGIN
    -- İlk kullanıcıyı bul
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    IF first_user_id IS NOT NULL THEN
        -- Bu kullanıcıyı admin yap (RLS yok, direkt ekleme)
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (first_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true,
            guncelleme_tarihi = NOW();
            
        RAISE NOTICE 'Admin kullanıcı oluşturuldu: %', first_user_id;
    ELSE
        RAISE NOTICE 'Henüz kullanıcı yok';
    END IF;
END $$;

-- 5. Sonuç kontrolü
SELECT 
    'RLS tamamen devre dışı - Admin sistemi aktif!' as durum,
    COUNT(*) as kalan_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 6. RLS durumunu kontrol et
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_aktif
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_roles', 'modeller', 'personel', 'tedarikciler', 'faturalar')
ORDER BY tablename;

-- 7. Admin kullanıcıları listele
SELECT 
    ur.user_id,
    ur.role,
    ur.aktif,
    u.email,
    'Admin - RLS kapalı, tam erişim' as durum
FROM public.user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'admin' AND ur.aktif = true;

-- 8. Test admin fonksiyonu
SELECT 
    public.admin_kontrol() as admin_mi,
    'Admin kontrol fonksiyonu test edildi' as test_mesaji;
