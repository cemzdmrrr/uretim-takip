-- MEVCUT AKSESUARLAR TABLOSUNU KONTROL ET VE GÜNCELLEYİCİ SCRIPT
-- Önce mevcut yapıyı kontrol edelim

-- Mevcut tablo yapısını göster
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'aksesuarlar' 
ORDER BY ordinal_position;

-- Mevcut verileri göster
SELECT * FROM aksesuarlar LIMIT 5;
