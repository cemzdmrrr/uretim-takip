-- Tamamlama için eksik sütun ekle
ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS tamamlanan_adet INTEGER DEFAULT 0;

ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS tamamlama_tarihi TIMESTAMP WITH TIME ZONE;

-- Test et
SELECT id, model_id, durum, tamamlanan_adet, tamamlama_tarihi, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;