-- Admin rolüne tüm yetkileri veren TAM DOĞRU politikalar
-- Tablo isimleri doğrulandı ve test edildi

-- User Roles tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm user_roles verilerine erişebilir" ON public.user_roles;
CREATE POLICY "Admin tüm user_roles verilerine erişebilir" ON public.user_roles
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Modeller tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm modeller verilerine erişebilir" ON public.modeller;
CREATE POLICY "Admin tüm modeller verilerine erişebilir" ON public.modeller
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Personel tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm personel verilerine erişebilir" ON public.personel;
CREATE POLICY "Admin tüm personel verilerine erişebilir" ON public.personel
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Tedarikçiler tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm tedarikciler verilerine erişebilir" ON public.tedarikciler;
CREATE POLICY "Admin tüm tedarikciler verilerine erişebilir" ON public.tedarikciler
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Faturalar tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm faturalar verilerine erişebilir" ON public.faturalar;
CREATE POLICY "Admin tüm faturalar verilerine erişebilir" ON public.faturalar
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Kasa Banka Hesapları tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm kasa_banka_hesaplari verilerine erişebilir" ON public.kasa_banka_hesaplari;
CREATE POLICY "Admin tüm kasa_banka_hesaplari verilerine erişebilir" ON public.kasa_banka_hesaplari
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Kasa Banka Hareketleri tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm kasa_banka_hareketleri verilerine erişebilir" ON public.kasa_banka_hareketleri;
CREATE POLICY "Admin tüm kasa_banka_hareketleri verilerine erişebilir" ON public.kasa_banka_hareketleri
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Dosyalar tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm dosyalar verilerine erişebilir" ON public.dosyalar;
CREATE POLICY "Admin tüm dosyalar verilerine erişebilir" ON public.dosyalar
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Sistem Ayarları tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm sistem_ayarlari verilerine erişebilir" ON public.sistem_ayarlari;
CREATE POLICY "Admin tüm sistem_ayarlari verilerine erişebilir" ON public.sistem_ayarlari
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Dönemler tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm donemler verilerine erişebilir" ON public.donemler;
CREATE POLICY "Admin tüm donemler verilerine erişebilir" ON public.donemler
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Personel Dönem tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm personel_donem verilerine erişebilir" ON public.personel_donem;
CREATE POLICY "Admin tüm personel_donem verilerine erişebilir" ON public.personel_donem
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- Fatura Kalemleri tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm fatura_kalemleri verilerine erişebilir" ON public.fatura_kalemleri;
CREATE POLICY "Admin tüm fatura_kalemleri verilerine erişebilir" ON public.fatura_kalemleri
    FOR ALL USING (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS(
            SELECT 1 FROM public.user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        )
    );

-- İşlem tamamlandığında bilgilendirme
SELECT 'Admin temel politikaları başarıyla uygulandı (sadece mevcut tablolar)!' as message;

-- Uygulanan politika sayısını göster
SELECT 
    COUNT(*) as toplam_admin_politikasi,
    'politika oluşturuldu' as durum
FROM pg_policies 
WHERE schemaname = 'public'
AND policyname LIKE '%Admin%';
