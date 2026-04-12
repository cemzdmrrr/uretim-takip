-- Dosyalar modülü için basit RLS politikaları

-- ÖNCE RLS'yi etkinleştir
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları sil
DROP POLICY IF EXISTS "dosyalar_select_policy" ON dosyalar;
DROP POLICY IF EXISTS "dosyalar_insert_policy" ON dosyalar;
DROP POLICY IF EXISTS "dosyalar_update_policy" ON dosyalar;
DROP POLICY IF EXISTS "dosyalar_delete_policy" ON dosyalar;
DROP POLICY IF EXISTS "dosya_paylasimlari_select_policy" ON dosya_paylasimlari;
DROP POLICY IF EXISTS "dosya_paylasimlari_insert_policy" ON dosya_paylasimlari;
DROP POLICY IF EXISTS "dosya_paylasimlari_update_policy" ON dosya_paylasimlari;
DROP POLICY IF EXISTS "dosya_paylasimlari_delete_policy" ON dosya_paylasimlari;

-- ==============================================
-- DOSYALAR TABLOSU POLİTİKALARI
-- ==============================================

-- 1. Dosyalar - Herkes kendi dosyalarını görebilir + genel erişimli dosyalar
CREATE POLICY "dosyalar_select" ON dosyalar
    FOR SELECT
    USING (
        olusturan_kullanici_id = auth.uid() OR 
        genel_erisim = true
    );

-- 2. Dosyalar - Sadece kimlik doğrulanmış kullanıcılar dosya ekleyebilir
CREATE POLICY "dosyalar_insert" ON dosyalar
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- 3. Dosyalar - Sadece dosya sahibi güncelleyebilir
CREATE POLICY "dosyalar_update" ON dosyalar
    FOR UPDATE
    USING (olusturan_kullanici_id = auth.uid());

-- 4. Dosyalar - Sadece dosya sahibi silebilir
CREATE POLICY "dosyalar_delete" ON dosyalar
    FOR DELETE
    USING (olusturan_kullanici_id = auth.uid());

-- ==============================================
-- DOSYA PAYLAŞIMLARI TABLOSU POLİTİKALARI
-- ==============================================

-- 1. Paylaşımlar - Paylaşan veya hedef kullanıcı görebilir
CREATE POLICY "paylasimlari_select" ON dosya_paylasimlari
    FOR SELECT
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

-- 2. Paylaşımlar - Sadece dosya sahibi paylaşabilir
CREATE POLICY "paylasimlari_insert" ON dosya_paylasimlari
    FOR INSERT
    WITH CHECK (paylasan_kullanici_id = auth.uid());

-- 3. Paylaşımlar - Sadece paylaşan güncelleyebilir
CREATE POLICY "paylasimlari_update" ON dosya_paylasimlari
    FOR UPDATE
    USING (paylasan_kullanici_id = auth.uid());

-- 4. Paylaşımlar - Paylaşan veya hedef silebilir
CREATE POLICY "paylasimlari_delete" ON dosya_paylasimlari
    FOR DELETE
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

-- Kontrol sorgusu
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari')
ORDER BY tablename, policyname;
