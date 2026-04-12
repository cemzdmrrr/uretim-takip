-- RLS Geri Açma - Sadece Mevcut Tablolar İçin
-- Bu script önce tabloları kontrol eder, sonra politika oluşturur

-- 1. Admin kontrol fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.is_admin_user()
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

-- 2. Mevcut tabloları listele ve RLS aç
DO $$
DECLARE
    tablo_adi text;
    tablolar text[] := ARRAY[
        'user_roles', 'modeller', 'personel', 'tedarikciler', 'faturalar', 
        'fatura_kalemleri', 'kasa_banka_hesaplari', 'kasa_banka_hareketleri',
        'dosyalar', 'sistem_ayarlari', 'donemler', 'personel_donem',
        'aksesuarlar', 'iplik_siparisler', 'dokuma_atamalari', 'konfeksiyon_atamalari',
        'yikama_atamalari', 'utu_atamalari', 'ilik_dugme_atamalari', 
        'kalite_kontrol_atamalari', 'paketleme_atamalari', 'izinler', 
        'mesailer', 'bordro', 'odemeler', 'triko_takip', 'uretim_kayitlari',
        'musteriler', 'siparisler'
    ];
BEGIN
    FOREACH tablo_adi IN ARRAY tablolar
    LOOP
        -- Tablo var mı kontrol et
        IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = tablo_adi AND schemaname = 'public') THEN
            -- RLS'i aç
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tablo_adi);
            RAISE NOTICE 'RLS açıldı: %', tablo_adi;
        ELSE
            RAISE NOTICE 'Tablo bulunamadı: %', tablo_adi;
        END IF;
    END LOOP;
END $$;

-- 3. Mevcut tablolar için admin politikaları oluştur
DO $$
DECLARE
    tablo_adi text;
    tablolar text[] := ARRAY[
        'modeller', 'personel', 'tedarikciler', 'faturalar', 
        'fatura_kalemleri', 'kasa_banka_hesaplari', 'kasa_banka_hareketleri',
        'dosyalar', 'sistem_ayarlari', 'donemler', 'personel_donem',
        'aksesuarlar', 'iplik_siparisler', 'dokuma_atamalari', 'konfeksiyon_atamalari',
        'yikama_atamalari', 'utu_atamalari', 'ilik_dugme_atamalari', 
        'kalite_kontrol_atamalari', 'paketleme_atamalari', 'izinler', 
        'mesailer', 'bordro', 'odemeler', 'triko_takip', 'uretim_kayitlari',
        'musteriler', 'siparisler'
    ];
BEGIN
    FOREACH tablo_adi IN ARRAY tablolar
    LOOP
        -- Tablo var mı kontrol et
        IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = tablo_adi AND schemaname = 'public') THEN
            -- Admin politikaları oluştur
            BEGIN
                EXECUTE format('CREATE POLICY "%s_admin_select" ON public.%I FOR SELECT USING (public.is_admin_user() OR true)', tablo_adi, tablo_adi);
                EXECUTE format('CREATE POLICY "%s_admin_insert" ON public.%I FOR INSERT WITH CHECK (public.is_admin_user())', tablo_adi, tablo_adi);
                EXECUTE format('CREATE POLICY "%s_admin_update" ON public.%I FOR UPDATE USING (public.is_admin_user())', tablo_adi, tablo_adi);
                EXECUTE format('CREATE POLICY "%s_admin_delete" ON public.%I FOR DELETE USING (public.is_admin_user())', tablo_adi, tablo_adi);
                RAISE NOTICE 'Admin politikaları oluşturuldu: %', tablo_adi;
            EXCEPTION
                WHEN duplicate_object THEN
                    RAISE NOTICE 'Politika zaten var: %', tablo_adi;
                WHEN others THEN
                    RAISE NOTICE 'Politika oluşturma hatası: % - %', tablo_adi, SQLERRM;
            END;
        END IF;
    END LOOP;
END $$;

-- 4. User_roles tablosu özel politikaları
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_roles' AND schemaname = 'public') THEN
        BEGIN
            -- Önceki politikaları sil
            DROP POLICY IF EXISTS "user_roles_own_select" ON public.user_roles;
            DROP POLICY IF EXISTS "user_roles_admin_insert" ON public.user_roles;
            DROP POLICY IF EXISTS "user_roles_admin_update" ON public.user_roles;
            DROP POLICY IF EXISTS "user_roles_admin_delete" ON public.user_roles;
            
            -- Yeni politikalar oluştur
            CREATE POLICY "user_roles_own_select" ON public.user_roles 
            FOR SELECT USING (user_id = auth.uid() OR public.is_admin_user());

            CREATE POLICY "user_roles_admin_insert" ON public.user_roles 
            FOR INSERT WITH CHECK (
                auth.uid() IN (
                    SELECT ur.user_id FROM public.user_roles ur 
                    WHERE ur.role = 'admin' AND ur.aktif = true
                )
            );

            CREATE POLICY "user_roles_admin_update" ON public.user_roles 
            FOR UPDATE USING (
                user_id = auth.uid() OR 
                auth.uid() IN (
                    SELECT ur.user_id FROM public.user_roles ur 
                    WHERE ur.role = 'admin' AND ur.aktif = true
                )
            );

            CREATE POLICY "user_roles_admin_delete" ON public.user_roles 
            FOR DELETE USING (
                auth.uid() IN (
                    SELECT ur.user_id FROM public.user_roles ur 
                    WHERE ur.role = 'admin' AND ur.aktif = true
                )
            );
            
            RAISE NOTICE 'user_roles özel politikaları oluşturuldu';
        EXCEPTION
            WHEN others THEN
                RAISE NOTICE 'user_roles politika hatası: %', SQLERRM;
        END;
    END IF;
END $$;

-- 5. Sonuç kontrolü
SELECT 
    'RLS tekrar aktif - Sadece mevcut tablolar!' as durum,
    COUNT(*) as aktif_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 6. Mevcut tabloları ve RLS durumunu göster
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_aktif,
    (SELECT COUNT(*) FROM pg_policies WHERE pg_policies.tablename = pg_tables.tablename) as politika_sayisi
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename NOT LIKE 'pg_%'
AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;

-- 7. Admin kullanıcı test kontrolü
SELECT 
    'Admin politika kontrolü' as test_turu,
    public.is_admin_user() as admin_mi,
    auth.uid() as mevcut_kullanici_id;

-- 8. Mevcut admin kullanıcıları göster
SELECT 
    ur.user_id,
    ur.role,
    ur.aktif,
    u.email,
    'Admin kullanıcı - Mevcut tablolarda tüm yetkiler aktif' as durum
FROM public.user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'admin' AND ur.aktif = true;
