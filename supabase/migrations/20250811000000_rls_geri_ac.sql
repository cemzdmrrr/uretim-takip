-- RLS'i Geri Açma ve Politikaları Yeniden Oluşturma
-- Bu migration RLS'i tekrar aktif hale getirir

-- 1. Tüm tabloların RLS'ini aç
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

-- 2. Basit admin politikaları oluştur (infinite recursion olmayan)
CREATE POLICY "Herkes okuyabilir" ON public.modeller FOR SELECT USING (true);
CREATE POLICY "Admin herşeyi yapabilir" ON public.modeller FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    )
);

CREATE POLICY "Herkes okuyabilir" ON public.personel FOR SELECT USING (true);
CREATE POLICY "Admin herşeyi yapabilir" ON public.personel FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    )
);

CREATE POLICY "Herkes okuyabilir" ON public.tedarikciler FOR SELECT USING (true);
CREATE POLICY "Admin herşeyi yapabilir" ON public.tedarikciler FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    )
);

-- 3. User_roles tablosu için özel politika (recursion olmayan)
CREATE POLICY "Kullanıcılar kendi rolünü görebilir" ON public.user_roles FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admin tüm rolleri yönetebilir" ON public.user_roles FOR ALL USING (
    user_id = auth.uid() OR 
    auth.uid() IN (
        SELECT user_id FROM public.user_roles 
        WHERE role = 'admin' AND aktif = true
    )
);

-- 4. Sonuç kontrolü
SELECT 
    'RLS tekrar aktif!' as durum,
    COUNT(*) as aktif_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public';
