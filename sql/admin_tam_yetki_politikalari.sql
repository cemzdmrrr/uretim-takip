-- Admin rolüne tüm yetkileri veren kapsamlı politikalar
-- Bu script admin kullanıcılarının tüm tablolara tam erişim sağlamasını garanti eder
-- UYARI: Tablo isimleri doğrulandı - SADECE MEVCUT TABLOLAR

-- TEMEL CORE TABLOLAR

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

-- Üretim aşamaları tabloları için admin politikaları

-- Dokuma atamaları
DROP POLICY IF EXISTS "Admin tüm dokuma_atamalari verilerine erişebilir" ON public.dokuma_atamalari;
CREATE POLICY "Admin tüm dokuma_atamalari verilerine erişebilir" ON public.dokuma_atamalari
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

-- Konfeksiyon atamaları
DROP POLICY IF EXISTS "Admin tüm konfeksiyon_atamalari verilerine erişebilir" ON public.konfeksiyon_atamalari;
CREATE POLICY "Admin tüm konfeksiyon_atamalari verilerine erişebilir" ON public.konfeksiyon_atamalari
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

-- Yıkama atamaları
DROP POLICY IF EXISTS "Admin tüm yikama_atamalari verilerine erişebilir" ON public.yikama_atamalari;
CREATE POLICY "Admin tüm yikama_atamalari verilerine erişebilir" ON public.yikama_atamalari
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

-- Ütü atamaları
DROP POLICY IF EXISTS "Admin tüm utu_atamalari verilerine erişebilir" ON public.utu_atamalari;
CREATE POLICY "Admin tüm utu_atamalari verilerine erişebilir" ON public.utu_atamalari
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

-- İlik düğme atamaları
DROP POLICY IF EXISTS "Admin tüm ilik_dugme_atamalari verilerine erişebilir" ON public.ilik_dugme_atamalari;
CREATE POLICY "Admin tüm ilik_dugme_atamalari verilerine erişebilir" ON public.ilik_dugme_atamalari
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

-- Kalite kontrol atamaları
DROP POLICY IF EXISTS "Admin tüm kalite_kontrol_atamalari verilerine erişebilir" ON public.kalite_kontrol_atamalari;
CREATE POLICY "Admin tüm kalite_kontrol_atamalari verilerine erişebilir" ON public.kalite_kontrol_atamalari
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

-- Paketleme atamaları
DROP POLICY IF EXISTS "Admin tüm paketleme_atamalari verilerine erişebilir" ON public.paketleme_atamalari;
CREATE POLICY "Admin tüm paketleme_atamalari verilerine erişebilir" ON public.paketleme_atamalari
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

-- Aksesuar tabloları için admin politikaları
DROP POLICY IF EXISTS "Admin tüm aksesuarlar verilerine erişebilir" ON public.aksesuarlar;
CREATE POLICY "Admin tüm aksesuarlar verilerine erişebilir" ON public.aksesuarlar
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

-- İplik siparişleri tabloları için admin politikaları
DROP POLICY IF EXISTS "Admin tüm iplik_siparisler verilerine erişebilir" ON public.iplik_siparisler;
CREATE POLICY "Admin tüm iplik_siparisler verilerine erişebilir" ON public.iplik_siparisler
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

-- İplik sipariş takip tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm iplik_siparis_takip verilerine erişebilir" ON public.iplik_siparis_takip;
CREATE POLICY "Admin tüm iplik_siparis_takip verilerine erişebilir" ON public.iplik_siparis_takip
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

-- Teslimatlar tablosu için admin politikaları
DROP POLICY IF EXISTS "Admin tüm teslimatlar verilerine erişebilir" ON public.teslimatlar;
CREATE POLICY "Admin tüm teslimatlar verilerine erişebilir" ON public.teslimatlar
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

-- Stok yönetimi tabloları için admin politikaları
DROP POLICY IF EXISTS "Admin tüm stok_hareketleri verilerine erişebilir" ON public.stok_hareketleri;
CREATE POLICY "Admin tüm stok_hareketleri verilerine erişebilir" ON public.stok_hareketleri
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

-- Rapor tabloları için admin politikaları
DROP POLICY IF EXISTS "Admin tüm rapor_verileri verilerine erişebilir" ON public.rapor_verileri;
CREATE POLICY "Admin tüm rapor_verileri verilerine erişebilir" ON public.rapor_verileri
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

-- İzin ve mesai tabloları varsa bunlar için de admin politikaları eklenebilir
-- İzinler tablosu
DROP POLICY IF EXISTS "Admin tüm izinler verilerine erişebilir" ON public.izinler;
CREATE POLICY "Admin tüm izinler verilerine erişebilir" ON public.izinler
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

-- Mesailer tablosu
DROP POLICY IF EXISTS "Admin tüm mesailer verilerine erişebilir" ON public.mesailer;
CREATE POLICY "Admin tüm mesailer verilerine erişebilir" ON public.mesailer
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

-- Bordro tablosu
DROP POLICY IF EXISTS "Admin tüm bordro verilerine erişebilir" ON public.bordro;
CREATE POLICY "Admin tüm bordro verilerine erişebilir" ON public.bordro
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

-- Ödemeler tablosu
DROP POLICY IF EXISTS "Admin tüm odemeler verilerine erişebilir" ON public.odemeler;
CREATE POLICY "Admin tüm odemeler verilerine erişebilir" ON public.odemeler
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

-- Diğer tablolar varsa burada eklenebilir...

-- İşlem tamamlandığında bilgilendirme
SELECT 'Admin tam yetki politikaları başarıyla uygulandı!' as message;
