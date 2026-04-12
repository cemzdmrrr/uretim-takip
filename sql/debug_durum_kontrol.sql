-- Mevcut durumu kontrol et
-- 1. Tabloyu ve constraint'leri kontrol et
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%dokuma_atamalari%durum%';

-- 2. Sütun bilgilerini kontrol et  
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
AND column_name IN ('durum', 'onay_tarihi', 'kabul_edilen_adet')
ORDER BY column_name;

-- 3. Mevcut veriyi kontrol et
SELECT id, model_id, durum, onay_tarihi, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;

-- 4. Manuel güncelleme test et
UPDATE dokuma_atamalari 
SET durum = 'onaylandi', onay_tarihi = now(), kabul_edilen_adet = 100
WHERE id = 25;

-- 5. Sonucu kontrol et
SELECT id, model_id, durum, onay_tarihi, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;