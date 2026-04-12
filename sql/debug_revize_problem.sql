-- Revize problemini debug etmek için tablo yapılarını kontrol et

-- 1. Dokuma atamaları tablosu yapısını kontrol et
\d dokuma_atamalari;

-- 2. Tamamlanan_adet kolonu var mı?
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
  AND column_name IN ('tamamlanan_adet', 'kabul_edilen_adet', 'tamamlama_tarihi', 'uretici_notlari')
ORDER BY column_name;

-- 3. Mevcut veriyi kontrol et
SELECT id, durum, adet, talep_edilen_adet, kabul_edilen_adet, tamamlanan_adet, tamamlama_tarihi
FROM dokuma_atamalari 
WHERE durum IN ('kismi_tamamlandi', 'tamamlandi')
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Constraints kontrol et
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'dokuma_atamalari';

-- 5. RLS politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'dokuma_atamalari';