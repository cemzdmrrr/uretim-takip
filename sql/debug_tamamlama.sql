-- 1. Mevcut kayıt durumunu kontrol et
SELECT id, model_id, durum, tamamlanan_adet, tamamlama_tarihi, kabul_edilen_adet, tedarikci_id, created_at
FROM dokuma_atamalari 
WHERE id = 25;

-- 2. Constraint kontrolü
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%dokuma_atamalari%durum%';

-- 3. Sütun varlığını kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
AND column_name IN ('durum', 'tamamlanan_adet', 'tamamlama_tarihi')
ORDER BY column_name;

-- 4. Manuel test güncelleme
UPDATE dokuma_atamalari 
SET durum = 'kismi_tamamlandi', tamamlanan_adet = 89, tamamlama_tarihi = NOW()
WHERE id = 25;

-- 5. Sonucu tekrar kontrol et
SELECT id, model_id, durum, tamamlanan_adet, tamamlama_tarihi, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;