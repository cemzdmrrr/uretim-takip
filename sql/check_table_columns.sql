-- dokuma_atamalari tablosu yapısını kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Mevcut veriyi kontrol et
SELECT id, siparis_modeli, durum, onay_tarihi, kabul_edilen_adet
FROM dokuma_atamalari 
WHERE id = 25;