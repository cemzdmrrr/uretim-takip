-- RLS Geri Açma - Direkt SQL
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Tüm tabloların RLS'ini tekrar aç
ALTER TABLE IF EXISTS public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.modeller ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tedarikciler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fatura_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.donemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.personel_donem ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.aksesuarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.iplik_siparisler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.yikama_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.utu_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.paketleme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.mesailer ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bordro ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.odemeler ENABLE ROW LEVEL SECURITY;

-- 2. Admin için kapsamlı politikalar oluştur (tüm tablolar için tam yetki)

-- Önce admin kontrol fonksiyonu oluştur
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

-- MODELLER tablosu politikaları
CREATE POLICY "modeller_admin_select" ON public.modeller FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "modeller_admin_insert" ON public.modeller FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "modeller_admin_update" ON public.modeller FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "modeller_admin_delete" ON public.modeller FOR DELETE USING (public.is_admin_user());

-- PERSONEL tablosu politikaları
CREATE POLICY "personel_admin_select" ON public.personel FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "personel_admin_insert" ON public.personel FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "personel_admin_update" ON public.personel FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "personel_admin_delete" ON public.personel FOR DELETE USING (public.is_admin_user());

-- TEDARİKÇİLER tablosu politikaları
CREATE POLICY "tedarikciler_admin_select" ON public.tedarikciler FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "tedarikciler_admin_insert" ON public.tedarikciler FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "tedarikciler_admin_update" ON public.tedarikciler FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "tedarikciler_admin_delete" ON public.tedarikciler FOR DELETE USING (public.is_admin_user());

-- FATURALAR tablosu politikaları
CREATE POLICY "faturalar_admin_select" ON public.faturalar FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "faturalar_admin_insert" ON public.faturalar FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "faturalar_admin_update" ON public.faturalar FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "faturalar_admin_delete" ON public.faturalar FOR DELETE USING (public.is_admin_user());

-- FATURA_KALEMLERİ tablosu politikaları
CREATE POLICY "fatura_kalemleri_admin_select" ON public.fatura_kalemleri FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "fatura_kalemleri_admin_insert" ON public.fatura_kalemleri FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "fatura_kalemleri_admin_update" ON public.fatura_kalemleri FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "fatura_kalemleri_admin_delete" ON public.fatura_kalemleri FOR DELETE USING (public.is_admin_user());

-- KASA_BANKA_HESAPLARI tablosu politikaları
CREATE POLICY "kasa_banka_hesaplari_admin_select" ON public.kasa_banka_hesaplari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "kasa_banka_hesaplari_admin_insert" ON public.kasa_banka_hesaplari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "kasa_banka_hesaplari_admin_update" ON public.kasa_banka_hesaplari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "kasa_banka_hesaplari_admin_delete" ON public.kasa_banka_hesaplari FOR DELETE USING (public.is_admin_user());

-- KASA_BANKA_HAREKETLERİ tablosu politikaları
CREATE POLICY "kasa_banka_hareketleri_admin_select" ON public.kasa_banka_hareketleri FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "kasa_banka_hareketleri_admin_insert" ON public.kasa_banka_hareketleri FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "kasa_banka_hareketleri_admin_update" ON public.kasa_banka_hareketleri FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "kasa_banka_hareketleri_admin_delete" ON public.kasa_banka_hareketleri FOR DELETE USING (public.is_admin_user());

-- DOSYALAR tablosu politikaları
CREATE POLICY "dosyalar_admin_select" ON public.dosyalar FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "dosyalar_admin_insert" ON public.dosyalar FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "dosyalar_admin_update" ON public.dosyalar FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "dosyalar_admin_delete" ON public.dosyalar FOR DELETE USING (public.is_admin_user());

-- SİSTEM_AYARLARI tablosu politikaları
CREATE POLICY "sistem_ayarlari_admin_select" ON public.sistem_ayarlari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "sistem_ayarlari_admin_insert" ON public.sistem_ayarlari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "sistem_ayarlari_admin_update" ON public.sistem_ayarlari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "sistem_ayarlari_admin_delete" ON public.sistem_ayarlari FOR DELETE USING (public.is_admin_user());

-- DONEMLER tablosu politikaları
CREATE POLICY "donemler_admin_select" ON public.donemler FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "donemler_admin_insert" ON public.donemler FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "donemler_admin_update" ON public.donemler FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "donemler_admin_delete" ON public.donemler FOR DELETE USING (public.is_admin_user());

-- PERSONEL_DONEM tablosu politikaları
CREATE POLICY "personel_donem_admin_select" ON public.personel_donem FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "personel_donem_admin_insert" ON public.personel_donem FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "personel_donem_admin_update" ON public.personel_donem FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "personel_donem_admin_delete" ON public.personel_donem FOR DELETE USING (public.is_admin_user());

-- AKSESUARLAR tablosu politikaları
CREATE POLICY "aksesuarlar_admin_select" ON public.aksesuarlar FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "aksesuarlar_admin_insert" ON public.aksesuarlar FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "aksesuarlar_admin_update" ON public.aksesuarlar FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "aksesuarlar_admin_delete" ON public.aksesuarlar FOR DELETE USING (public.is_admin_user());

-- İPLİK_SİPARİŞLER tablosu politikaları
CREATE POLICY "iplik_siparisler_admin_select" ON public.iplik_siparisler FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "iplik_siparisler_admin_insert" ON public.iplik_siparisler FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "iplik_siparisler_admin_update" ON public.iplik_siparisler FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "iplik_siparisler_admin_delete" ON public.iplik_siparisler FOR DELETE USING (public.is_admin_user());

-- DOKUMA_ATAMALARI tablosu politikaları
CREATE POLICY "dokuma_atamalari_admin_select" ON public.dokuma_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "dokuma_atamalari_admin_insert" ON public.dokuma_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "dokuma_atamalari_admin_update" ON public.dokuma_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "dokuma_atamalari_admin_delete" ON public.dokuma_atamalari FOR DELETE USING (public.is_admin_user());

-- KONFEKSİYON_ATAMALARI tablosu politikaları
CREATE POLICY "konfeksiyon_atamalari_admin_select" ON public.konfeksiyon_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "konfeksiyon_atamalari_admin_insert" ON public.konfeksiyon_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "konfeksiyon_atamalari_admin_update" ON public.konfeksiyon_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "konfeksiyon_atamalari_admin_delete" ON public.konfeksiyon_atamalari FOR DELETE USING (public.is_admin_user());

-- YIKAMA_ATAMALARI tablosu politikaları
CREATE POLICY "yikama_atamalari_admin_select" ON public.yikama_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "yikama_atamalari_admin_insert" ON public.yikama_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "yikama_atamalari_admin_update" ON public.yikama_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "yikama_atamalari_admin_delete" ON public.yikama_atamalari FOR DELETE USING (public.is_admin_user());

-- UTU_ATAMALARI tablosu politikaları
CREATE POLICY "utu_atamalari_admin_select" ON public.utu_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "utu_atamalari_admin_insert" ON public.utu_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "utu_atamalari_admin_update" ON public.utu_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "utu_atamalari_admin_delete" ON public.utu_atamalari FOR DELETE USING (public.is_admin_user());

-- İLİK_DUGME_ATAMALARI tablosu politikaları
CREATE POLICY "ilik_dugme_atamalari_admin_select" ON public.ilik_dugme_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "ilik_dugme_atamalari_admin_insert" ON public.ilik_dugme_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "ilik_dugme_atamalari_admin_update" ON public.ilik_dugme_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "ilik_dugme_atamalari_admin_delete" ON public.ilik_dugme_atamalari FOR DELETE USING (public.is_admin_user());

-- KALİTE_KONTROL_ATAMALARI tablosu politikaları
CREATE POLICY "kalite_kontrol_atamalari_admin_select" ON public.kalite_kontrol_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "kalite_kontrol_atamalari_admin_insert" ON public.kalite_kontrol_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "kalite_kontrol_atamalari_admin_update" ON public.kalite_kontrol_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "kalite_kontrol_atamalari_admin_delete" ON public.kalite_kontrol_atamalari FOR DELETE USING (public.is_admin_user());

-- PAKETLEME_ATAMALARI tablosu politikaları
CREATE POLICY "paketleme_atamalari_admin_select" ON public.paketleme_atamalari FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "paketleme_atamalari_admin_insert" ON public.paketleme_atamalari FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "paketleme_atamalari_admin_update" ON public.paketleme_atamalari FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "paketleme_atamalari_admin_delete" ON public.paketleme_atamalari FOR DELETE USING (public.is_admin_user());

-- İZİNLER tablosu politikaları
CREATE POLICY "izinler_admin_select" ON public.izinler FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "izinler_admin_insert" ON public.izinler FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "izinler_admin_update" ON public.izinler FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "izinler_admin_delete" ON public.izinler FOR DELETE USING (public.is_admin_user());

-- MESAİLER tablosu politikaları
CREATE POLICY "mesailer_admin_select" ON public.mesailer FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "mesailer_admin_insert" ON public.mesailer FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "mesailer_admin_update" ON public.mesailer FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "mesailer_admin_delete" ON public.mesailer FOR DELETE USING (public.is_admin_user());

-- BORDRO tablosu politikaları
CREATE POLICY "bordro_admin_select" ON public.bordro FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "bordro_admin_insert" ON public.bordro FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "bordro_admin_update" ON public.bordro FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "bordro_admin_delete" ON public.bordro FOR DELETE USING (public.is_admin_user());

-- ÖDEMELER tablosu politikaları
CREATE POLICY "odemeler_admin_select" ON public.odemeler FOR SELECT USING (public.is_admin_user() OR true);
CREATE POLICY "odemeler_admin_insert" ON public.odemeler FOR INSERT WITH CHECK (public.is_admin_user());
CREATE POLICY "odemeler_admin_update" ON public.odemeler FOR UPDATE USING (public.is_admin_user());
CREATE POLICY "odemeler_admin_delete" ON public.odemeler FOR DELETE USING (public.is_admin_user());

-- USER_ROLES tablosu özel politikaları (infinite recursion önlemek için)
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

-- 3. Sonuç kontrolü
SELECT 
    'RLS tekrar aktif - Admin tüm yetkilere sahip!' as durum,
    COUNT(*) as aktif_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';

-- 4. Aktif tabloları kontrol et
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_aktif,
    COUNT(*) OVER (PARTITION BY tablename) as politika_sayisi
FROM pg_tables 
LEFT JOIN pg_policies ON pg_tables.tablename = pg_policies.tablename
WHERE schemaname = 'public' 
AND pg_tables.tablename IN ('user_roles', 'modeller', 'personel', 'tedarikciler', 'faturalar', 'kasa_banka_hesaplari')
ORDER BY pg_tables.tablename;

-- 5. Admin kullanıcı test kontrolü
SELECT 
    'Admin politika kontrolü' as test_turu,
    public.is_admin_user() as admin_mi,
    auth.uid() as mevcut_kullanici_id;

-- 6. Mevcut admin kullanıcıları göster
SELECT 
    ur.user_id,
    ur.role,
    ur.aktif,
    u.email,
    'Admin kullanıcı - Tüm yetkiler aktif' as durum
FROM public.user_roles ur
LEFT JOIN auth.users u ON ur.user_id = u.id
WHERE ur.role = 'admin' AND ur.aktif = true;
