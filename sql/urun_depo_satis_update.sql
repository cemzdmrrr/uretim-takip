-- Ürün Depo Tablosuna Satış Kolonları Ekleme
-- Bu script ile satış takibi yapılabilir

-- Satış durumu için yeni kolonlar
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS satildi BOOLEAN DEFAULT FALSE;
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS satilan_adet INT DEFAULT 0;
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS satilan_tutar DECIMAL(12,2) DEFAULT 0;
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS satis_tarihi TIMESTAMP WITH TIME ZONE;

-- Marka ve renk bilgileri (model_id üzerinden triko_takip'ten çekilebilir ama 
-- hızlı erişim için buraya da ekleyebiliriz)
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS marka VARCHAR(100);
ALTER TABLE urun_depo ADD COLUMN IF NOT EXISTS renk VARCHAR(100);

-- Kalan adet hesaplaması için view
CREATE OR REPLACE VIEW urun_depo_detay AS
SELECT 
    ud.*,
    (ud.adet - COALESCE(ud.satilan_adet, 0)) as kalan_adet,
    tt.item_no,
    tt.renk as model_renk,
    tt.marka as model_marka,
    tt.urun_cinsi
FROM urun_depo ud
LEFT JOIN triko_takip tt ON ud.model_id = tt.id;

-- Satış index'i
CREATE INDEX IF NOT EXISTS idx_urun_depo_satildi ON urun_depo(satildi);
CREATE INDEX IF NOT EXISTS idx_urun_depo_satis_tarihi ON urun_depo(satis_tarihi);

-- Mevcut kayıtlar için marka ve renk bilgilerini güncelle
UPDATE urun_depo ud
SET 
    marka = tt.marka,
    renk = tt.renk
FROM triko_takip tt
WHERE ud.model_id = tt.id
AND (ud.marka IS NULL OR ud.renk IS NULL);

-- Test
SELECT 
    'Güncelleme tamamlandı' as durum,
    COUNT(*) as toplam_kayit,
    COUNT(*) FILTER (WHERE satildi = true) as satilan_kayit
FROM urun_depo;
