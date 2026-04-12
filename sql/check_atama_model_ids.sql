-- Atama tablosundaki model_id değerlerini kontrol et
SELECT id, model_id, model_adi, durum
FROM atamalar
WHERE model_id = 'abf2fef6-9d13-4766-bb4b-da2db2e30105'
LIMIT 5;

-- Veya son atamalar
SELECT id, model_id, model_adi, durum
FROM atamalar
ORDER BY created_at DESC
LIMIT 5;
