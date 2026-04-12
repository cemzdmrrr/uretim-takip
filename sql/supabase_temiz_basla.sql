-- TAMAMEN TEMİZ BAŞLANGIÇ - TABLOLARI SİL VE YENİDEN OLUŞTUR

-- 1. Önce tüm bağımlılıkları sil
DROP POLICY IF EXISTS dosyalar_all ON dosyalar;
DROP POLICY IF EXISTS dosya_paylasimlari_all ON dosya_paylasimlari;

-- Mevcut tüm politikaları sil
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosyalar') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosyalar';
    END LOOP;
    
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosya_paylasimlari') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosya_paylasimlari';
    END LOOP;
    
    RAISE NOTICE 'Tüm politikalar silindi';
END $$;

-- 2. Tabloları sil
DROP TABLE IF EXISTS dosya_paylasimlari CASCADE;
DROP TABLE IF EXISTS dosyalar CASCADE;

-- 3. Tabloları yeniden oluştur
CREATE TABLE dosyalar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ad VARCHAR(255) NOT NULL,
    dosya_turu VARCHAR(20) DEFAULT 'pdf',
    boyut BIGINT DEFAULT 0,
    yol TEXT NOT NULL,
    ust_klasor_id UUID,
    aciklama TEXT,
    olusturan_kullanici_id UUID,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true,
    genel_erisim BOOLEAN DEFAULT false,
    son_erisim_tarihi TIMESTAMP WITH TIME ZONE,
    erisim_sayisi INTEGER DEFAULT 0,
    mime_type VARCHAR(100)
);

CREATE TABLE dosya_paylasimlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID,
    paylasan_kullanici_id UUID,
    hedef_kullanici_id UUID,
    izin_turu VARCHAR(20) DEFAULT 'read',
    paylasim_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true
);

-- 4. Foreign key'leri ekle
ALTER TABLE dosyalar ADD CONSTRAINT fk_ust_klasor 
    FOREIGN KEY (ust_klasor_id) REFERENCES dosyalar(id) ON DELETE CASCADE;

ALTER TABLE dosya_paylasimlari ADD CONSTRAINT fk_dosya 
    FOREIGN KEY (dosya_id) REFERENCES dosyalar(id) ON DELETE CASCADE;

-- 5. Indexler
CREATE INDEX idx_dosyalar_olusturan ON dosyalar(olusturan_kullanici_id);
CREATE INDEX idx_dosyalar_ust_klasor ON dosyalar(ust_klasor_id);

-- 6. RLS etkinleştir
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- 7. EN BASIT POLİTİKALAR
CREATE POLICY "dosyalar_herkese_acik" ON dosyalar FOR ALL USING (true);
CREATE POLICY "paylasimlari_herkese_acik" ON dosya_paylasimlari FOR ALL USING (true);

-- Kontrol
SELECT 'Tablolar ve politikalar başarıyla oluşturuldu!' as sonuc;

SELECT 
    tablename,
    policyname
FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari');
