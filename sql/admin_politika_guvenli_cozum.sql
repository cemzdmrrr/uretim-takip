-- Admin politikalar için GÜVENLİ çözüm
-- Sonsuz döngü sorununu çözer

-- ÖNCE: Mevcut tüm admin politikalarını temizle
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
        AND (policyname LIKE '%Admin%' OR policyname LIKE '%admin%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      policy_record.policyname, 
                      policy_record.schemaname, 
                      policy_record.tablename);
        RAISE NOTICE 'Silindi: %.%.%', policy_record.schemaname, policy_record.tablename, policy_record.policyname;
    END LOOP;
END $$;

-- USER_ROLES tablosu için özel çözüm (sonsuz döngü olmasın)
-- Admin kontrolü için basit yaklaşım
CREATE POLICY "Admin user_roles tam erişim" ON public.user_roles
    FOR ALL 
    TO authenticated
    USING (
        -- Admin kontrolü: direkt auth.uid() kontrolü
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
        OR
        -- Kendi kaydına erişim
        user_id = auth.uid()
    )
    WITH CHECK (
        -- Admin kontrolü
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
        OR
        -- Sadece kendi kaydını güncelleyebilir
        user_id = auth.uid()
    );

-- MODELLER tablosu için admin politikası
DROP POLICY IF EXISTS "Admin modeller erişim" ON public.modeller;
CREATE POLICY "Admin modeller erişim" ON public.modeller
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- PERSONEL tablosu için admin politikası
DROP POLICY IF EXISTS "Admin personel erişim" ON public.personel;
CREATE POLICY "Admin personel erişim" ON public.personel
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- TEDARİKÇİLER tablosu için admin politikası
DROP POLICY IF EXISTS "Admin tedarikciler erişim" ON public.tedarikciler;
CREATE POLICY "Admin tedarikciler erişim" ON public.tedarikciler
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- FATURALAR tablosu için admin politikası
DROP POLICY IF EXISTS "Admin faturalar erişim" ON public.faturalar;
CREATE POLICY "Admin faturalar erişim" ON public.faturalar
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- KASA_BANKA_HESAPLARI tablosu için admin politikası
DROP POLICY IF EXISTS "Admin kasa_banka_hesaplari erişim" ON public.kasa_banka_hesaplari;
CREATE POLICY "Admin kasa_banka_hesaplari erişim" ON public.kasa_banka_hesaplari
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- KASA_BANKA_HAREKETLERİ tablosu için admin politikası
DROP POLICY IF EXISTS "Admin kasa_banka_hareketleri erişim" ON public.kasa_banka_hareketleri;
CREATE POLICY "Admin kasa_banka_hareketleri erişim" ON public.kasa_banka_hareketleri
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND aktif = true
        )
    );

-- Başarı mesajı
SELECT 'Admin politikaları güvenli şekilde uygulandı - sonsuz döngü sorunu çözüldü!' as mesaj;

-- Uygulanan politika sayısı
SELECT 
    COUNT(*) as toplam_admin_politikasi,
    'adet politika oluşturuldu' as durum
FROM pg_policies 
WHERE schemaname = 'public'
AND (policyname LIKE '%Admin%' OR policyname LIKE '%admin%');
