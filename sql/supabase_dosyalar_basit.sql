-- Dosyalar modülü için basitleştirilmiş schema

-- 1. Dosyalar tablosu
CREATE TABLE IF NOT EXISTS dosyalar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ad VARCHAR(255) NOT NULL,
    dosya_turu VARCHAR(20) DEFAULT 'pdf' CHECK (dosya_turu IN ('pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'folder')),
    boyut BIGINT DEFAULT 0,
    yol TEXT NOT NULL,
    ust_klasor_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    aciklama TEXT,
    olusturan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true,
    genel_erisim BOOLEAN DEFAULT false,
    son_erisim_tarihi TIMESTAMP WITH TIME ZONE,
    erisim_sayisi INTEGER DEFAULT 0,
    mime_type VARCHAR(100)
);

-- 2. Dosya paylaşımları tablosu
CREATE TABLE IF NOT EXISTS dosya_paylasimlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    paylasan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    hedef_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    izin_turu VARCHAR(20) DEFAULT 'read' CHECK (izin_turu IN ('read', 'write', 'admin')),
    paylasim_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true
);

-- 3. Indexler
CREATE INDEX IF NOT EXISTS idx_dosyalar_ust_klasor ON dosyalar(ust_klasor_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_olusturan ON dosyalar(olusturan_kullanici_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_dosya_turu ON dosyalar(dosya_turu) WHERE aktif = true;

-- 4. Güncelleme tarihi trigger'ı
CREATE OR REPLACE FUNCTION update_guncelleme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Mevcut trigger'ı sil ve yeniden oluştur
DROP TRIGGER IF EXISTS dosyalar_guncelleme_tarihi ON dosyalar;
CREATE TRIGGER dosyalar_guncelleme_tarihi
    BEFORE UPDATE ON dosyalar
    FOR EACH ROW
    EXECUTE FUNCTION update_guncelleme_tarihi();

-- 5. RLS Politikaları
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları sil
DROP POLICY IF EXISTS dosyalar_select_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_insert_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_update_policy ON dosyalar;
DROP POLICY IF EXISTS dosyalar_delete_policy ON dosyalar;
DROP POLICY IF EXISTS dosya_paylasimlari_select_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_insert_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_update_policy ON dosya_paylasimlari;
DROP POLICY IF EXISTS dosya_paylasimlari_delete_policy ON dosya_paylasimlari;

-- Dosyalar SELECT politikası
CREATE POLICY dosyalar_select_policy ON dosyalar
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

-- Dosyalar INSERT politikası
CREATE POLICY dosyalar_insert_policy ON dosyalar
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Dosyalar UPDATE politikası
CREATE POLICY dosyalar_update_policy ON dosyalar
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
    );

-- Dosyalar DELETE politikası
CREATE POLICY dosyalar_delete_policy ON dosyalar
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

-- Paylaşımlar SELECT politikası
CREATE POLICY dosya_paylasimlari_select_policy ON dosya_paylasimlari
    FOR SELECT
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

-- Paylaşımlar INSERT politikası
CREATE POLICY dosya_paylasimlari_insert_policy ON dosya_paylasimlari
    FOR INSERT
    WITH CHECK (
        paylasan_kullanici_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND d.olusturan_kullanici_id = auth.uid()
        )
    );

-- Paylaşımlar UPDATE/DELETE politikaları
CREATE POLICY dosya_paylasimlari_update_policy ON dosya_paylasimlari
    FOR UPDATE
    USING (paylasan_kullanici_id = auth.uid());

CREATE POLICY dosya_paylasimlari_delete_policy ON dosya_paylasimlari
    FOR DELETE
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

-- NOTLAR:
-- 1. Bu dosyayı Supabase SQL Editor'da çalıştırın
-- 2. Storage bucket'ını manuel oluşturun: 'dosyalar' (public=false)
-- 3. Storage policies'i Dashboard'dan ekleyin (supabase_storage_policies.sql dosyasındaki kodları kullanın)
