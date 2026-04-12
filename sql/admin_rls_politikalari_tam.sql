-- TÜM TABLOLAR İÇİN ADMİN KONTROLLÜ RLS POLİTİKALARI
-- user_roles tablosunda role='admin' olan kullanıcılar tüm işlemleri yapabilir

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

-- 3. TÜM TABLOLARIN RLS'İNİ AKTİF ET (ŞEMAYA GÖRE)
-- Kullanıcı ve rol yönetimi tabloları
ALTER TABLE IF EXISTS public.user_roles ENABLE ROW LEVEL SECURITY;

-- Personel ve insan kaynakları tabloları
ALTER TABLE IF EXISTS public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel_arsiv ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel_donem ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.mesai ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.puantaj ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bordro ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.odemeler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.odeme_kayitlari ENABLE ROW LEVEL SECURITY;

-- Dönem ve tarih yönetimi
ALTER TABLE IF EXISTS public.donemler ENABLE ROW LEVEL SECURITY;

-- Müşteri ve tedarikçi yönetimi
ALTER TABLE IF EXISTS public.musteriler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tedarikciler ENABLE ROW LEVEL SECURITY;

-- Üretim ve takip tabloları
ALTER TABLE IF EXISTS public.triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.uretim_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.uretim_plani ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yukleme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fire_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sevkiyat_kayitlari ENABLE ROW LEVEL SECURITY;

-- Atama tabloları
ALTER TABLE IF EXISTS public.dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari ENABLE ROW LEVEL SECURITY;

-- Fatura ve mali işlemler
ALTER TABLE IF EXISTS public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fatura_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;

-- İplik yönetimi
ALTER TABLE IF EXISTS public.iplik_stoklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.iplik_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.iplik_siparisleri ENABLE ROW LEVEL SECURITY;

-- Aksesuar yönetimi
ALTER TABLE IF EXISTS public.aksesuarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.aksesuar_bedenler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.aksesuar_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.aksesuar_stok_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.model_aksesuar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.model_aksesuar_bedenler ENABLE ROW LEVEL SECURITY;

-- Atölye ve firma yönetimi
ALTER TABLE IF EXISTS public.atolyeler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.atolye_kapasite_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.firma_kullanicilari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ozel_personel ENABLE ROW LEVEL SECURITY;

-- Sevkiyat ve lojistik
ALTER TABLE IF EXISTS public.sevk_talepleri ENABLE ROW LEVEL SECURITY;

-- Model ve ürün yönetimi
ALTER TABLE IF EXISTS public.modeller ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.model_kritikleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.model_workflow_gecmisi ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.maliyet_hesaplama ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.teknik_dosyalar ENABLE ROW LEVEL SECURITY;

-- Bildirim ve dosya yönetimi
ALTER TABLE IF EXISTS public.bildirimler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- Sistem tabloları
ALTER TABLE IF EXISTS public.sirket_bilgileri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.loglar ENABLE ROW LEVEL SECURITY;

-- 4. USER_ROLES TABLOSU POLİTİKALARI (Infinite recursion önlemek için özel)
CREATE POLICY "user_roles_own_read" ON public.user_roles 
FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "user_roles_admin_all" ON public.user_roles 
FOR ALL USING (
    auth.uid() IN (
        SELECT ur.user_id FROM public.user_roles ur 
        WHERE ur.role = 'admin' AND ur.aktif = true
    )
);

-- 5. GENEL ADMİN POLİTİKALARI - ŞEMAYA GÖRE ÖZEL TABLOLAR

-- BİLDİRİMLER TABLOSU (kullanıcı bazlı erişim)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'bildirimler') THEN
        CREATE POLICY "bildirimler_own_admin" ON public.bildirimler 
        FOR ALL USING (user_id = auth.uid() OR public.is_admin());
        RAISE NOTICE 'bildirimler politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'bildirimler tablosu bulunamadı';
    END IF;
END $$;

-- PERSONEL TABLOSU
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'personel') THEN
        CREATE POLICY "personel_read_all" ON public.personel FOR SELECT USING (true);
        CREATE POLICY "personel_admin_write" ON public.personel FOR INSERT WITH CHECK (public.is_admin());
        CREATE POLICY "personel_admin_update" ON public.personel FOR UPDATE USING (public.is_admin());
        CREATE POLICY "personel_admin_delete" ON public.personel FOR DELETE USING (public.is_admin());
        RAISE NOTICE 'personel politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'personel tablosu bulunamadı';
    END IF;
END $$;

-- PERSONEL ARŞİV TABLOSU (kullanıcı veya admin erişimi)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'personel_arsiv') THEN
        CREATE POLICY "personel_arsiv_own_admin" ON public.personel_arsiv 
        FOR ALL USING (yukleyen_user_id = auth.uid() OR public.is_admin());
        RAISE NOTICE 'personel_arsiv politikaları oluşturüldu';
    ELSE
        RAISE NOTICE 'personel_arsiv tablosu bulunamadı';
    END IF;
END $$;

-- İZİNLER TABLOSU (kullanıcı kendi izinleri + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'izinler') THEN
        CREATE POLICY "izinler_own_admin" ON public.izinler 
        FOR ALL USING (user_id = auth.uid() OR public.is_admin());
        RAISE NOTICE 'izinler politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'izinler tablosu bulunamadı';
    END IF;
END $$;

-- MESAİ TABLOSU (kullanıcı kendi mesaisi + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'mesai') THEN
        CREATE POLICY "mesai_own_admin" ON public.mesai 
        FOR ALL USING (user_id = auth.uid() OR public.is_admin());
        RAISE NOTICE 'mesai politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'mesai tablosu bulunamadı';
    END IF;
END $$;

-- PUANTAJ TABLOSU (personel kendi puantajı + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'puantaj') THEN
        CREATE POLICY "puantaj_own_admin" ON public.puantaj 
        FOR ALL USING (
            personel_id IN (SELECT user_id FROM public.personel WHERE user_id = auth.uid()) 
            OR public.is_admin()
        );
        RAISE NOTICE 'puantaj politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'puantaj tablosu bulunamadı';
    END IF;
END $$;

-- ÖDEMELER TABLOSU (kullanıcı kendi ödemeleri + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'odemeler') THEN
        CREATE POLICY "odemeler_own_admin" ON public.odemeler 
        FOR ALL USING (user_id = auth.uid() OR public.is_admin());
        RAISE NOTICE 'odemeler politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'odemeler tablosu bulunamadı';
    END IF;
END $$;

-- DOSYALAR TABLOSU (dosya sahibi + genel erişim + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dosyalar') THEN
        CREATE POLICY "dosyalar_own_public_admin" ON public.dosyalar 
        FOR ALL USING (
            olusturan_kullanici_id = auth.uid() 
            OR genel_erisim = true 
            OR public.is_admin()
        );
        RAISE NOTICE 'dosyalar politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'dosyalar tablosu bulunamadı';
    END IF;
END $$;

-- DOSYA PAYLAŞIMLARI (paylaşan/hedef kullanıcı + admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dosya_paylasimlari') THEN
        CREATE POLICY "dosya_paylasimlari_own_admin" ON public.dosya_paylasimlari 
        FOR ALL USING (
            paylasan_kullanici_id = auth.uid() 
            OR hedef_kullanici_id = auth.uid() 
            OR public.is_admin()
        );
        RAISE NOTICE 'dosya_paylasimlari politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'dosya_paylasimlari tablosu bulunamadı';
    END IF;
END $$;

-- LOGLAR TABLOSU (sadece admin)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'loglar') THEN
        CREATE POLICY "loglar_admin_only" ON public.loglar 
        FOR ALL USING (public.is_admin());
        RAISE NOTICE 'loglar politikaları oluşturuldu';
    ELSE
        RAISE NOTICE 'loglar tablosu bulunamadı';
    END IF;
END $$;

-- GENEL TABLOLAR İÇİN OTOMATİK POLİTİKA OLUŞTURMA
DO $$
DECLARE
    tablo_record RECORD;
    policy_count INTEGER := 0;
    -- Özel politikalara sahip tablolar (bu tablolar için otomatik politika oluşturma)
    ozel_tablolar text[] := ARRAY[
        'user_roles', 'bildirimler', 'personel', 'personel_arsiv', 
        'izinler', 'mesai', 'puantaj', 'odemeler', 'dosyalar', 
        'dosya_paylasimlari', 'loglar'
    ];
BEGIN
    FOR tablo_record IN 
        SELECT table_name as tablename 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        AND table_name NOT LIKE 'pg_%'
        AND table_name NOT LIKE 'sql_%'
        AND table_name NOT LIKE '%_backup'  -- Backup tabloları hariç
        AND table_name != ALL(ozel_tablolar) -- Özel tablolar hariç
    LOOP
        BEGIN
            -- Herkes okuyabilir (üretim verileri görünürlük için)
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
    
    RAISE NOTICE 'Otomatik politika oluşturma tamamlandı. Toplam % politika oluşturuldu', policy_count;
END $$;

-- 7. İLK KULLANICIYI ADMİN YAP
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

-- 9. ADMİN KULLANICILARI GÖSTER
SELECT 
    'Admin kullanıcılar' as tip,
    u.id,
    u.email,
    ur.role,
    ur.aktif,
    'Tüm tablolarda tam yetkili' as durum
FROM auth.users u
INNER JOIN public.user_roles ur ON u.id = ur.user_id
WHERE ur.role = 'admin' AND ur.aktif = true;

-- 10. FONKSİYON TESTİ
SELECT 
    'Admin kontrol fonksiyon testi' as test_turu,
    public.is_admin() as admin_mi,
    auth.uid() as mevcut_kullanici_id;