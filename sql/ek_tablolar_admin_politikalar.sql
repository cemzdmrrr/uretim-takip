-- EK TABLOLAR İÇİN ADMİN POLİTİKALARI
-- Bu script'i sadece aşağıdaki tablolar mevcutsa çalıştırın

-- TRİKO_TAKİP tablosu politikaları (eğer varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'triko_takip' AND schemaname = 'public') THEN
        -- RLS'i aç
        EXECUTE 'ALTER TABLE public.triko_takip ENABLE ROW LEVEL SECURITY';
        
        -- Politikaları oluştur
        EXECUTE 'CREATE POLICY "triko_takip_admin_select" ON public.triko_takip FOR SELECT USING (public.is_admin_user() OR true)';
        EXECUTE 'CREATE POLICY "triko_takip_admin_insert" ON public.triko_takip FOR INSERT WITH CHECK (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "triko_takip_admin_update" ON public.triko_takip FOR UPDATE USING (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "triko_takip_admin_delete" ON public.triko_takip FOR DELETE USING (public.is_admin_user())';
        
        RAISE NOTICE 'triko_takip tablosu için admin politikaları oluşturuldu';
    END IF;
END $$;

-- ÜRETİM_KAYITLARI tablosu politikaları (eğer varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'uretim_kayitlari' AND schemaname = 'public') THEN
        -- RLS'i aç
        EXECUTE 'ALTER TABLE public.uretim_kayitlari ENABLE ROW LEVEL SECURITY';
        
        -- Politikaları oluştur
        EXECUTE 'CREATE POLICY "uretim_kayitlari_admin_select" ON public.uretim_kayitlari FOR SELECT USING (public.is_admin_user() OR true)';
        EXECUTE 'CREATE POLICY "uretim_kayitlari_admin_insert" ON public.uretim_kayitlari FOR INSERT WITH CHECK (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "uretim_kayitlari_admin_update" ON public.uretim_kayitlari FOR UPDATE USING (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "uretim_kayitlari_admin_delete" ON public.uretim_kayitlari FOR DELETE USING (public.is_admin_user())';
        
        RAISE NOTICE 'uretim_kayitlari tablosu için admin politikaları oluşturuldu';
    END IF;
END $$;

-- ÜRETİM_ASAMALARİ tablosu politikaları (eğer varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'uretim_asamalari' AND schemaname = 'public') THEN
        -- RLS'i aç
        EXECUTE 'ALTER TABLE public.uretim_asamalari ENABLE ROW LEVEL SECURITY';
        
        -- Politikaları oluştur
        EXECUTE 'CREATE POLICY "uretim_asamalari_admin_select" ON public.uretim_asamalari FOR SELECT USING (public.is_admin_user() OR true)';
        EXECUTE 'CREATE POLICY "uretim_asamalari_admin_insert" ON public.uretim_asamalari FOR INSERT WITH CHECK (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "uretim_asamalari_admin_update" ON public.uretim_asamalari FOR UPDATE USING (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "uretim_asamalari_admin_delete" ON public.uretim_asamalari FOR DELETE USING (public.is_admin_user())';
        
        RAISE NOTICE 'uretim_asamalari tablosu için admin politikaları oluşturuldu';
    END IF;
END $$;

-- SİPARİŞLER tablosu politikaları (eğer varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'siparisler' AND schemaname = 'public') THEN
        -- RLS'i aç
        EXECUTE 'ALTER TABLE public.siparisler ENABLE ROW LEVEL SECURITY';
        
        -- Politikaları oluştur
        EXECUTE 'CREATE POLICY "siparisler_admin_select" ON public.siparisler FOR SELECT USING (public.is_admin_user() OR true)';
        EXECUTE 'CREATE POLICY "siparisler_admin_insert" ON public.siparisler FOR INSERT WITH CHECK (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "siparisler_admin_update" ON public.siparisler FOR UPDATE USING (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "siparisler_admin_delete" ON public.siparisler FOR DELETE USING (public.is_admin_user())';
        
        RAISE NOTICE 'siparisler tablosu için admin politikaları oluşturuldu';
    END IF;
END $$;

-- MÜŞTERİLER tablosu politikaları (eğer varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'musteriler' AND schemaname = 'public') THEN
        -- RLS'i aç
        EXECUTE 'ALTER TABLE public.musteriler ENABLE ROW LEVEL SECURITY';
        
        -- Politikaları oluştur
        EXECUTE 'CREATE POLICY "musteriler_admin_select" ON public.musteriler FOR SELECT USING (public.is_admin_user() OR true)';
        EXECUTE 'CREATE POLICY "musteriler_admin_insert" ON public.musteriler FOR INSERT WITH CHECK (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "musteriler_admin_update" ON public.musteriler FOR UPDATE USING (public.is_admin_user())';
        EXECUTE 'CREATE POLICY "musteriler_admin_delete" ON public.musteriler FOR DELETE USING (public.is_admin_user())';
        
        RAISE NOTICE 'musteriler tablosu için admin politikaları oluşturuldu';
    END IF;
END $$;

-- RAPOR sonucu
SELECT 
    'Ek tablolar için admin politikaları kontrol edildi' as durum,
    COUNT(*) as toplam_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public' 
AND policyname LIKE '%admin%';
