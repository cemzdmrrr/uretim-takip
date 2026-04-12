-- Supabase Storage Bucket ve RLS Politikaları
-- DİKKAT: Bu komutlar Supabase Dashboard'dan çalıştırılmalıdır

-- 1. Storage bucket oluştur (Dashboard'dan yapılmalı)
-- Bucket adı: 'dosyalar'
-- Public: false

-- 2. Storage RLS politikalarını ekle

-- SELECT Policy (Dosya okuma)
CREATE POLICY "Dosya Okuma İzni" ON storage.objects
    FOR SELECT 
    USING (
        bucket_id = 'dosyalar' AND 
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.yol = name 
            AND d.aktif = true
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                d.genel_erisim = true OR
                auth.uid() = ANY(d.izinli_kullanicilar) OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.aktif = true
                    AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
                )
            )
        )
    );

-- INSERT Policy (Dosya yükleme)
CREATE POLICY "Dosya Yükleme İzni" ON storage.objects
    FOR INSERT 
    WITH CHECK (
        bucket_id = 'dosyalar' AND 
        auth.uid() IS NOT NULL
    );

-- UPDATE Policy (Dosya güncelleme)
CREATE POLICY "Dosya Güncelleme İzni" ON storage.objects
    FOR UPDATE 
    USING (
        bucket_id = 'dosyalar' AND 
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.yol = name 
            AND d.aktif = true
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.izin_turu IN ('write', 'admin')
                    AND dp.aktif = true
                    AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
                )
            )
        )
    );

-- DELETE Policy (Dosya silme)
CREATE POLICY "Dosya Silme İzni" ON storage.objects
    FOR DELETE 
    USING (
        bucket_id = 'dosyalar' AND 
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.yol = name 
            AND d.aktif = true
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.izin_turu = 'admin'
                    AND dp.aktif = true
                    AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
                )
            )
        )
    );

-- Storage bucket'ında RLS'yi aktifleştir (otomatik aktif)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY; -- Zaten aktif

/*
NOTLAR:
1. Bu politikalar Supabase Dashboard > Storage > Policies kısmından manuel eklenmeli
2. Bucket'ı önce Dashboard'dan oluşturun: Storage > New Bucket > 'dosyalar'
3. Bucket ayarları: Public=false, Allowed file types: pdf,doc,docx,xls,xlsx,jpg,jpeg,png
4. Her policy için ayrı ayrı "New Policy" butonuna tıklayıp definition'ları yapıştırın
*/
