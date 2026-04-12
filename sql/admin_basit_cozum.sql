-- En basit admin çözümü - sonsuz döngü riski yok

-- Önce tüm RLS'i devre dışı bırak
ALTER TABLE public.user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.modeller DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikciler DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.faturalar DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hesaplari DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hareketleri DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.dosyalar DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sistem_ayarlari DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.donemler DISABLE ROW LEVEL SECURITY;

-- Admin kullanıcıları için basit kontrol
-- Bu fonksiyon sonsuz döngüye girmez
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS boolean AS $$
BEGIN
    -- Direkt kontrol - döngü riski yok
    RETURN EXISTS (
        SELECT 1 
        FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin' 
        AND aktif = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Şimdi RLS'i tekrar aç ve basit politikalar uygula
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modeller ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikciler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donemler ENABLE ROW LEVEL SECURITY;

-- Basit admin politikaları
CREATE POLICY "admin_access" ON public.user_roles FOR ALL USING (is_admin_user() OR user_id = auth.uid());
CREATE POLICY "admin_access" ON public.modeller FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.personel FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.tedarikciler FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.faturalar FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.kasa_banka_hesaplari FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.kasa_banka_hareketleri FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.dosyalar FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.sistem_ayarlari FOR ALL USING (is_admin_user());
CREATE POLICY "admin_access" ON public.donemler FOR ALL USING (is_admin_user());

SELECT 'En basit admin çözümü uygulandı!' as mesaj;
