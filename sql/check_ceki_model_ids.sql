-- Ceki listesindeki model_id değerlerini kontrol et
SELECT id, model_id, adet, koli_adedi, gonderim_durumu
FROM ceki_listesi 
ORDER BY created_at DESC 
LIMIT 5;

-- Modeller tablosundan UUID'leri göster
SELECT id, model_adi, model_kodu 
FROM modeller 
LIMIT 5;
