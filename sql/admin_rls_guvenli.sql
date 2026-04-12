-- GÜVENLİ ADMİN RLS POLİTİKALARI
-- Sadece mevcut tablolar için politika oluşturur

-- 1. ADMİN KONTROL FONKSİYONU
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. ÖNCE TÜM POLİTİKALARI TEMİZLE
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                          policy_record.policyname, 
                          policy_record.schemaname, 
                          policy_record.tablename);
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'Politika silme hatası: %.%.%', 
                             policy_record.schemaname, 
                             policy_record.tablename, 
                             policy_record.policyname;
        END;
    END LOOP;
END $$;

-- 3. TÜM MEVCUT TABLOLARIN RLS'İNİ AKTİF ET
DO $$
DECLARE
    tablo_record RECORD;
BEGIN
    FOR tablo_record IN 
        SELECT tablename 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tablo_record.tablename);
            RAISE NOTICE 'RLS aktif edildi: %', tablo_record.tablename;
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'RLS aktif etme hatası: % - %', tablo_record.tablename, SQLERRM;
        END;
    END LOOP;
END $$;

-- 4. USER_ROLES TABLOSU POLİTİKALARI (Infinite recursion önlemek için özel)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles') THEN
        CREATE POLICY "user_roles_own_read" ON public.user_roles 
        FOR SELECT USING (user_id = auth.uid());

        CREATE POLICY "user_roles_admin_all" ON public.user_roles 
        FOR ALL USING (
            auth.uid() IN (
                SELECT ur.user_id FROM public.user_roles ur 
                WHERE ur.role = 'admin' AND ur.aktif = true
            )
        );
        RAISE NOTICE 'user_roles politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'user_roles tablosu bulunamadı';
    END IF;
END $$;

-- 5. TÜM MEVCUT TABLOLAR İÇİN POLİTİKA OLUŞTUR
DO $$
DECLARE
    tablo_record RECORD;
    policy_count INTEGER := 0;
BEGIN
    FOR tablo_record IN 
        SELECT tablename 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        AND tablename NOT LIKE 'pg_%'
        AND tablename NOT LIKE 'sql_%'
        AND tablename != 'user_roles' -- Bu zaten yukarıda işlendi
    LOOP
        BEGIN
            -- Herkes okuyabilir
            EXECUTE format('CREATE POLICY "%s_read_all" ON public.%I FOR SELECT USING (true)', 
                          tablo_record.tablename, tablo_record.tablename);
            
            -- Sadece admin yazabilir
            EXECUTE format('CREATE POLICY "%s_admin_write" ON public.%I FOR INSERT WITH CHECK (public.is_admin())', 
                          tablo_record.tablename, tablo_record.tablename);
            
            -- Sadece admin güncelleyebilir
            EXECUTE format('CREATE POLICY "%s_admin_update" ON public.%I FOR UPDATE USING (public.is_admin())', 
                          tablo_record.tablename, tablo_record.tablename);
            
            -- Sadece admin silebilir
            EXECUTE format('CREATE POLICY "%s_admin_delete" ON public.%I FOR DELETE USING (public.is_admin())', 
                          tablo_record.tablename, tablo_record.tablename);
            
            policy_count := policy_count + 4;
            RAISE NOTICE '% tablosu için 4 politika oluşturuldu', tablo_record.tablename;
            
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'Politika oluşturma hatası: % - %', tablo_record.tablename, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE 'Toplam % politika oluşturuldu', policy_count;
END $$;

-- 6. ÖZEL DURUMLAR İÇİN EK POLİTİKALAR

-- Kullanıcılar tablosu varsa kendi verilerine erişim
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'kullanicilar') THEN
        -- Önce mevcut politikayı sil
        DROP POLICY IF EXISTS "kullanicilar_read_all" ON public.kullanicilar;
        
        -- Kendi verilerini veya admin tüm verileri görebilir
        CREATE POLICY "kullanicilar_own_or_admin" ON public.kullanicilar 
        FOR SELECT USING (id = auth.uid() OR public.is_admin());
        
        RAISE NOTICE 'kullanicilar için özel politika oluşturuldu';
    END IF;
END $$;

-- Notifications tablosu varsa kendi bildirimlerine erişim
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        -- Önce mevcut politikayı sil
        DROP POLICY IF EXISTS "notifications_read_all" ON public.notifications;
        
        -- Kendi bildirimlerini veya admin tüm bildirimleri görebilir
        CREATE POLICY "notifications_own_or_admin" ON public.notifications 
        FOR SELECT USING (user_id = auth.uid() OR public.is_admin());
        
        RAISE NOTICE 'notifications için özel politika oluşturuldu';
    END IF;
END $$;

-- 7. İLK KULLANICIYI ADMİN YAP
DO $$
DECLARE
    first_user_id UUID;
    current_user_id UUID;
BEGIN
    -- user_roles tablosu var mı kontrol et
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles') THEN
        RAISE NOTICE 'user_roles tablosu bulunamadı, admin atama atlanıyor';
        RETURN;
    END IF;

    -- Mevcut oturum kullanıcısını al
    current_user_id := auth.uid();
    
    -- İlk kullanıcıyı al
    SELECT id INTO first_user_id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1;
    
    -- Eğer oturum açık kullanıcı varsa onu admin yap
    IF current_user_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (current_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
            
        RAISE NOTICE 'Mevcut kullanıcı admin yapıldı: %', current_user_id;
    END IF;
    
    -- İlk kullanıcıyı da admin yap (farklıysa)
    IF first_user_id IS NOT NULL AND (current_user_id IS NULL OR first_user_id != current_user_id) THEN
        INSERT INTO public.user_roles (user_id, role, aktif)
        VALUES (first_user_id, 'admin', true)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            role = 'admin',
            aktif = true;
            
        RAISE NOTICE 'İlk kullanıcı admin yapıldı: %', first_user_id;
    END IF;
END $$;

-- 8. SONUÇ KONTROLÜ
SELECT 
    'Admin RLS politikaları başarıyla uygulandı!' as durum,
    COUNT(*) as aktif_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 9. MEVCUT TABLOLAR VE RLS DURUMLARI
SELECT 
    'Tablo durumu' as tip,
    tablename as tablo_adi,
    CASE WHEN rowsecurity THEN 'Aktif' ELSE 'Pasif' END as rls_durum,
    (SELECT COUNT(*) FROM pg_policies WHERE pg_policies.tablename = pg_tables.tablename) as politika_sayisi
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 10. ADMİN KULLANICILARI GÖSTER (EĞER user_roles VARSA)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles') THEN
        -- Admin kullanıcıları göster için sorgu hazırla
        RAISE NOTICE 'Admin kullanıcılar kontrol edilebilir:';
        RAISE NOTICE 'SELECT u.email, ur.role, ur.aktif FROM auth.users u INNER JOIN public.user_roles ur ON u.id = ur.user_id WHERE ur.role = ''admin'';';
    ELSE
        RAISE NOTICE 'user_roles tablosu bulunamadı, admin listesi gösterilemiyor';
    END IF;
END $$;

-- 11. FONKSİYON TESTİ
SELECT 
    'Admin kontrol fonksiyon testi' as test_turu,
    public.is_admin() as admin_mi,
    auth.uid() as mevcut_kullanici_id;