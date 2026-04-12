-- İplik Sipariş Takip Sistemi Schema Düzeltmesi

-- Önce mevcut tablonun yapısını kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'iplik_siparisleri' 
ORDER BY ordinal_position;

-- İplik siparisleri tablosundaki iplik_adi sütununu opsiyonel hale getir
-- (Eğer sipariş seviyesinde iplik adı gerekmiyorsa - kalemler seviyesinde var)
ALTER TABLE iplik_siparisleri 
ALTER COLUMN iplik_adi DROP NOT NULL;
