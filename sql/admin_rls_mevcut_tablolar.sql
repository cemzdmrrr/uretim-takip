-- MEVCUT TABLOLAR İÇİN ADMİN KONTROLLÜ RLS POLİTİKALARI
-- Sadece var olan tablolar için politika oluşturur

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

-- 3. MEVCUT TABLOLARI KONTROL ET VE RLS AKTİF ET
DO $$
DECLARE
    tablo_adi text;
    tablolar text[] := ARRAY[
        'user_roles', 'personel', 'tedarikciler', 'triko_takip', 'faturalar', 
        'fatura_kalemleri', 'kasa_banka_hesaplari', 'kasa_banka_hareketleri',
        'iplik_stoklari', 'iplik_hareketleri', 'aksesuarlar', 'musteriler',
        'izinler', 'mesai', 'bordro', 'donemler', 'sistem_ayarlari',
        'dokuma_atamalari', 'konfeksiyon_atamalari', 'yikama_atamalari',
        'utu_atamalari', 'notifications', 'yukleme_kayitlari', 'fire_kayitlari',
        'tedarikci_siparisleri', 'tedarikci_odemeleri', 'sirket_bilgileri',
        'gelir_vergisi_dilimleri', 'envanter', 'is_takip', 'puantaj',
        'odeme_kayitlari', 'aksesuar_beden', 'model_aksesuar'
    ];
BEGIN
    FOREACH tablo_adi IN ARRAY tablolar
    LOOP
        -- Tablo var mı kontrol et
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = tablo_adi
        ) THEN
            BEGIN
                EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tablo_adi);
                RAISE NOTICE 'RLS aktif edildi: %', tablo_adi;
            EXCEPTION
                WHEN others THEN
                    RAISE NOTICE 'RLS aktif etme hatası: % - %', tablo_adi, SQLERRM;
            END;
        ELSE
            RAISE NOTICE 'Tablo bulunamadı: %', tablo_adi;
        END IF;
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
    END IF;
END $$;

-- 5. GENEL TABLOLAR İÇİN POLİTİKALAR

-- PERSONEL TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'personel') THEN
        CREATE POLICY "personel_read_all" ON public.personel FOR SELECT USING (true);
        CREATE POLICY "personel_admin_write" ON public.personel FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "personel_admin_update" ON public.personel FOR UPDATE USING (public.is_admin());
        CREATE POLICY "personel_admin_delete" ON public.personel FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'personel politikaları oluşturuldu';
    END IF;
END $$;

-- TEDARİKÇİLER TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tedarikciler') THEN
        CREATE POLICY "tedarikciler_read_all" ON public.tedarikciler FOR SELECT USING (true);
        CREATE POLICY "tedarikciler_admin_write" ON public.tedarikciler FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "tedarikciler_admin_update" ON public.tedarikciler FOR UPDATE USING (public.is_admin());
        CREATE POLICY "tedarikciler_admin_delete" ON public.tedarikciler FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'tedarikciler politikaları oluşturuldu';
    END IF;
END $$;

-- TRİKO TAKİP TABLOSU (MODELLER)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'triko_takip') THEN
        CREATE POLICY "triko_takip_read_all" ON public.triko_takip FOR SELECT USING (true);
        CREATE POLICY "triko_takip_admin_write" ON public.triko_takip FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "triko_takip_admin_update" ON public.triko_takip FOR UPDATE USING (public.is_admin());
        CREATE POLICY "triko_takip_admin_delete" ON public.triko_takip FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'triko_takip politikaları oluşturuldu';
    END IF;
END $$;

-- FATURALAR TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'faturalar') THEN
        CREATE POLICY "faturalar_read_all" ON public.faturalar FOR SELECT USING (true);
        CREATE POLICY "faturalar_admin_write" ON public.faturalar FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "faturalar_admin_update" ON public.faturalar FOR UPDATE USING (public.is_admin());
        CREATE POLICY "faturalar_admin_delete" ON public.faturalar FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'faturalar politikaları oluşturuldu';
    END IF;
END $$;

-- FATURA KALEMLERİ TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'fatura_kalemleri') THEN
        CREATE POLICY "fatura_kalemleri_read_all" ON public.fatura_kalemleri FOR SELECT USING (true);
        CREATE POLICY "fatura_kalemleri_admin_write" ON public.fatura_kalemleri FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "fatura_kalemleri_admin_update" ON public.fatura_kalemleri FOR UPDATE USING (public.is_admin());
        CREATE POLICY "fatura_kalemleri_admin_delete" ON public.fatura_kalemleri FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'fatura_kalemleri politikaları oluşturuldu';
    END IF;
END $$;

-- KASA BANKA HESAPLARI TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'kasa_banka_hesaplari') THEN
        CREATE POLICY "kasa_banka_hesaplari_read_all" ON public.kasa_banka_hesaplari FOR SELECT USING (true);
        CREATE POLICY "kasa_banka_hesaplari_admin_write" ON public.kasa_banka_hesaplari FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "kasa_banka_hesaplari_admin_update" ON public.kasa_banka_hesaplari FOR UPDATE USING (public.is_admin());
        CREATE POLICY "kasa_banka_hesaplari_admin_delete" ON public.kasa_banka_hesaplari FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'kasa_banka_hesaplari politikaları oluşturuldu';
    END IF;
END $$;

-- KASA BANKA HAREKETLERİ TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'kasa_banka_hareketleri') THEN
        CREATE POLICY "kasa_banka_hareketleri_read_all" ON public.kasa_banka_hareketleri FOR SELECT USING (true);
        CREATE POLICY "kasa_banka_hareketleri_admin_write" ON public.kasa_banka_hareketleri FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "kasa_banka_hareketleri_admin_update" ON public.kasa_banka_hareketleri FOR UPDATE USING (public.is_admin());
        CREATE POLICY "kasa_banka_hareketleri_admin_delete" ON public.kasa_banka_hareketleri FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'kasa_banka_hareketleri politikaları oluşturuldu';
    END IF;
END $$;

-- MÜŞTERİLER TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'musteriler') THEN
        CREATE POLICY "musteriler_read_all" ON public.musteriler FOR SELECT USING (true);
        CREATE POLICY "musteriler_admin_write" ON public.musteriler FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "musteriler_admin_update" ON public.musteriler FOR UPDATE USING (public.is_admin());
        CREATE POLICY "musteriler_admin_delete" ON public.musteriler FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'musteriler politikaları oluşturuldu';
    END IF;
END $$;

-- AKSESUARLAR TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'aksesuarlar') THEN
        CREATE POLICY "aksesuarlar_read_all" ON public.aksesuarlar FOR SELECT USING (true);
        CREATE POLICY "aksesuarlar_admin_write" ON public.aksesuarlar FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "aksesuarlar_admin_update" ON public.aksesuarlar FOR UPDATE USING (public.is_admin());
        CREATE POLICY "aksesuarlar_admin_delete" ON public.aksesuarlar FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'aksesuarlar politikaları oluşturuldu';
    END IF;
END $$;

-- DOKUMA ATAMALARI TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dokuma_atamalari') THEN
        CREATE POLICY "dokuma_atamalari_read_all" ON public.dokuma_atamalari FOR SELECT USING (true);
        CREATE POLICY "dokuma_atamalari_admin_write" ON public.dokuma_atamalari FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "dokuma_atamalari_admin_update" ON public.dokuma_atamalari FOR UPDATE USING (public.is_admin());
        CREATE POLICY "dokuma_atamalari_admin_delete" ON public.dokuma_atamalari FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'dokuma_atamalari politikaları oluşturuldu';
    END IF;
END $$;

-- KONFEKSİYON ATAMALARI TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'konfeksiyon_atamalari') THEN
        CREATE POLICY "konfeksiyon_atamalari_read_all" ON public.konfeksiyon_atamalari FOR SELECT USING (true);
        CREATE POLICY "konfeksiyon_atamalari_admin_write" ON public.konfeksiyon_atamalari FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "konfeksiyon_atamalari_admin_update" ON public.konfeksiyon_atamalari FOR UPDATE USING (public.is_admin());
        CREATE POLICY "konfeksiyon_atamalari_admin_delete" ON public.konfeksiyon_atamalari FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'konfeksiyon_atamalari politikaları oluşturuldu';
    END IF;
END $$;

-- DIĞER ATAMA TABLOLARI İÇİN BENZER YAPILAR
DO $$
DECLARE
    atama_tablolari text[] := ARRAY[
        'yikama_atamalari', 'utu_atamalari', 'ilik_dugme_atamalari', 
        'kalite_kontrol_atamalari', 'paketleme_atamalari'
    ];
    tablo_adi text;
BEGIN
    FOREACH tablo_adi IN ARRAY atama_tablolari
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tablo_adi) THEN
            EXECUTE format('CREATE POLICY "%s_read_all" ON public.%I FOR SELECT USING (true)', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_write" ON public.%I FOR INSERT WITH CHECK (public.is_admin())', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_update" ON public.%I FOR UPDATE USING (public.is_admin())', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_delete" ON public.%I FOR DELETE USING (public.is_admin())', tablo_adi, tablo_adi);
            RAISE NOTICE '% politikaları oluşturuldu', tablo_adi;
        END IF;
    END LOOP;
END $$;

-- DIĞER GENEL TABLOLAR İÇİN
DO $$
DECLARE
    genel_tablolar text[] := ARRAY[
        'izinler', 'mesai', 'bordro', 'donemler', 'sistem_ayarlari',
        'notifications', 'yukleme_kayitlari', 'fire_kayitlari',
        'tedarikci_siparisleri', 'tedarikci_odemeleri', 'sirket_bilgileri',
        'gelir_vergisi_dilimleri', 'envanter', 'is_takip', 'puantaj',
        'odeme_kayitlari', 'aksesuar_beden', 'model_aksesuar',
        'iplik_stoklari', 'iplik_hareketleri'
    ];
    tablo_adi text;
BEGIN
    FOREACH tablo_adi IN ARRAY genel_tablolar
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tablo_adi) THEN
            EXECUTE format('CREATE POLICY "%s_read_all" ON public.%I FOR SELECT USING (true)', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_write" ON public.%I FOR INSERT WITH CHECK (public.is_admin())', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_update" ON public.%I FOR UPDATE USING (public.is_admin())', tablo_adi, tablo_adi);
            EXECUTE format('CREATE POLICY "%s_admin_delete" ON public.%I FOR DELETE USING (public.is_admin())', tablo_adi, tablo_adi);
            RAISE NOTICE '% politikaları oluşturuldu', tablo_adi;
        END IF;
    END LOOP;
END $$;

-- 6. İLK KULLANICIYI ADMİN YAP
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

-- 7. SONUÇ KONTROLÜ
SELECT 
    'Admin RLS politikaları başarıyla uygulandı!' as durum,
    COUNT(*) as aktif_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 8. MEVCUT TABLOLAR LİSTESİ
SELECT 
    'Mevcut tablolar ve RLS durumları' as baslik,
    tablename,
    CASE WHEN rowsecurity THEN 'Aktif' ELSE 'Pasif' END as rls_durum
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 9. ADMİN KULLANICILARI GÖSTER (EĞER user_roles VARSA)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles') THEN
        -- Admin kullanıcıları göster
        RAISE NOTICE 'Admin kullanıcılar sorgusu çalıştırılıyor...';
    ELSE
        RAISE NOTICE 'user_roles tablosu bulunamadı, admin listesi gösterilemiyor';
    END IF;
END $$;

-- 10. FONKSİYON TESTİ
SELECT 
    'Admin kontrol fonksiyon testi' as test_turu,
    public.is_admin() as admin_mi,
    auth.uid() as mevcut_kullanici_id;