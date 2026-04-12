-- Dosyalar modülü RLS politikaları - SADECE POLİTİKALAR

-- ÖNCE RLS'yi etkinleştir
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- DOSYALAR TABLOSU POLİTİKALARI
-- ==============================================

-- 1. DOSYALAR SELECT POLİTİKASI
CREATE POLICY "dosyalar_select_policy" ON dosyalar
    FOR SELECT
    USING (
        aktif = true AND (
            olusturan_kullanici_id = auth.uid() OR
            genel_erisim = true OR
            EXISTS (
                SELECT 1 FROM dosya_paylasimlari dp
                WHERE dp.dosya_id = id 
                AND dp.hedef_kullanici_id = auth.uid() 
                AND dp.aktif = true
            )
        )
    );

-- 2. DOSYALAR INSERT POLİTİKASI
CREATE POLICY "dosyalar_insert_policy" ON dosyalar
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL AND
        olusturan_kullanici_id = auth.uid()
    );

-- 3. DOSYALAR UPDATE POLİTİKASI
CREATE POLICY "dosyalar_update_policy" ON dosyalar
    FOR UPDATE
    USING (
        aktif = true AND (
            olusturan_kullanici_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM dosya_paylasimlari dp
                WHERE dp.dosya_id = id 
                AND dp.hedef_kullanici_id = auth.uid() 
                AND dp.izin_turu IN ('write', 'admin')
                AND dp.aktif = true
            )
        )
    )
    WITH CHECK (
        olusturan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.izin_turu IN ('write', 'admin')
            AND dp.aktif = true
        )
    );

-- 4. DOSYALAR DELETE POLİTİKASI
CREATE POLICY "dosyalar_delete_policy" ON dosyalar
    FOR DELETE
    USING (
        olusturan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.izin_turu = 'admin'
            AND dp.aktif = true
        )
    );

-- ==============================================
-- DOSYA PAYLAŞIMLARI TABLOSU POLİTİKALARI
-- ==============================================

-- 1. PAYLAŞIMLAR SELECT POLİTİKASI
CREATE POLICY "dosya_paylasimlari_select_policy" ON dosya_paylasimlari
    FOR SELECT
    USING (
        aktif = true AND (
            paylasan_kullanici_id = auth.uid() OR 
            hedef_kullanici_id = auth.uid()
        )
    );

-- 2. PAYLAŞIMLAR INSERT POLİTİKASI
CREATE POLICY "dosya_paylasimlari_insert_policy" ON dosya_paylasimlari
    FOR INSERT
    WITH CHECK (
        paylasan_kullanici_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND d.olusturan_kullanici_id = auth.uid()
            AND d.aktif = true
        )
    );

-- 3. PAYLAŞIMLAR UPDATE POLİTİKASI
CREATE POLICY "dosya_paylasimlari_update_policy" ON dosya_paylasimlari
    FOR UPDATE
    USING (
        aktif = true AND
        paylasan_kullanici_id = auth.uid()
    )
    WITH CHECK (
        paylasan_kullanici_id = auth.uid()
    );

-- 4. PAYLAŞIMLAR DELETE POLİTİKASI
CREATE POLICY "dosya_paylasimlari_delete_policy" ON dosya_paylasimlari
    FOR DELETE
    USING (
        aktif = true AND (
            paylasan_kullanici_id = auth.uid() OR 
            hedef_kullanici_id = auth.uid()
        )
    );

-- Politikaları kontrol et
SELECT 
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari')
ORDER BY tablename, policyname;
