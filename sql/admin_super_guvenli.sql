-- SÜPER GÜVENLİ Admin çözümü
-- Sonsuz döngü garantili çözüm

-- Mevcut politikaları temizle
DROP POLICY IF EXISTS "admin_access" ON public.user_roles;
DROP POLICY IF EXISTS "admin_access" ON public.modeller;
DROP POLICY IF EXISTS "admin_access" ON public.personel;
DROP POLICY IF EXISTS "admin_access" ON public.tedarikciler;
DROP POLICY IF EXISTS "admin_access" ON public.faturalar;
DROP POLICY IF EXISTS "admin_access" ON public.kasa_banka_hesaplari;
DROP POLICY IF EXISTS "admin_access" ON public.kasa_banka_hareketleri;
DROP POLICY IF EXISTS "admin_access" ON public.dosyalar;
DROP POLICY IF EXISTS "admin_access" ON public.sistem_ayarlari;
DROP POLICY IF EXISTS "admin_access" ON public.donemler;

-- Admin kontrolü için güvenli fonksiyon
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean AS $$
DECLARE
    user_role text;
BEGIN
    -- auth.uid() kullanarak güvenli kontrol
    SELECT role INTO user_role 
    FROM public.user_roles 
    WHERE user_id = auth.uid() 
    AND aktif = true
    LIMIT 1;
    
    RETURN COALESCE(user_role = 'admin', false);
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- USER_ROLES için özel politika (kendi kaydına erişim + admin erişimi)
CREATE POLICY "user_roles_policy" ON public.user_roles
    FOR ALL 
    USING (
        -- Kendi kaydına erişim (sonsuz döngü yok)
        user_id = auth.uid()
        OR
        -- Admin erişimi (güvenli fonksiyon)
        auth.is_admin()
    )
    WITH CHECK (
        user_id = auth.uid()
        OR
        auth.is_admin()
    );

-- Diğer tablolar için admin politikaları
CREATE POLICY "modeller_admin_policy" ON public.modeller
    FOR ALL USING (auth.is_admin());

CREATE POLICY "personel_admin_policy" ON public.personel
    FOR ALL USING (auth.is_admin());

CREATE POLICY "tedarikciler_admin_policy" ON public.tedarikciler
    FOR ALL USING (auth.is_admin());

CREATE POLICY "faturalar_admin_policy" ON public.faturalar
    FOR ALL USING (auth.is_admin());

CREATE POLICY "kasa_banka_hesaplari_admin_policy" ON public.kasa_banka_hesaplari
    FOR ALL USING (auth.is_admin());

CREATE POLICY "kasa_banka_hareketleri_admin_policy" ON public.kasa_banka_hareketleri
    FOR ALL USING (auth.is_admin());

CREATE POLICY "dosyalar_admin_policy" ON public.dosyalar
    FOR ALL USING (auth.is_admin());

CREATE POLICY "sistem_ayarlari_admin_policy" ON public.sistem_ayarlari
    FOR ALL USING (auth.is_admin());

CREATE POLICY "donemler_admin_policy" ON public.donemler
    FOR ALL USING (auth.is_admin());

-- Test admin fonksiyonu
SELECT 
    'Admin güvenli politikaları uygulandı!' as mesaj,
    auth.is_admin() as admin_mi;

-- Politika sayısını göster
SELECT COUNT(*) as toplam_politika
FROM pg_policies 
WHERE schemaname = 'public';
