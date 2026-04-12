-- kalite_kontrol_atamalari tablosuna eksik sütunu ekle
ALTER TABLE kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS adet INTEGER DEFAULT 0;

-- Mevcut yapıyı kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'kalite_kontrol_atamalari' 
AND table_schema = 'public'
ORDER BY ordinal_position;