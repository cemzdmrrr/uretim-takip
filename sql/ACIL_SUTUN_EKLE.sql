-- HIZLI ÇÖZÜM: dokuma_atamalari tablosunda durum constraint'ini düzelt
-- Problem: durum sütunu 'onaylandi' değerini kabul etmiyor

-- 1. Mevcut constraint'i kaldır
ALTER TABLE dokuma_atamalari 
DROP CONSTRAINT IF EXISTS dokuma_atamalari_durum_check;

-- 2. Yeni constraint ekle (onaylandi dahil)
ALTER TABLE dokuma_atamalari 
ADD CONSTRAINT dokuma_atamalari_durum_check 
CHECK (durum = ANY (ARRAY['atandi'::text, 'onaylandi'::text, 'baslatildi'::text, 'tamamlandi'::text, 'iptal'::text]));

-- 3. onay_tarihi sütunu zaten var mı kontrol et, yoksa ekle
ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP with time zone;

-- 4. kabul_edilen_adet sütunu zaten var mı kontrol et, yoksa ekle  
ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS kabul_edilen_adet INTEGER;

-- 5. Test verisi güncelle
UPDATE dokuma_atamalari 
SET durum = 'atandi' 
WHERE id = 25;

-- 6. Sonucu kontrol et
SELECT id, model_id, durum, onay_tarihi, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;

-- 7. Şema kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari' 
AND table_schema = 'public'
ORDER BY ordinal_position;