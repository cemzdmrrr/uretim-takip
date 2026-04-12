-- Yukleme kayitlari tablosundaki son kayıtları göster
SELECT 
  id,
  model_id,
  adet,
  tarih,
  kaynak,
  ceki_id,
  created_at
FROM yukleme_kayitlari
ORDER BY created_at DESC
LIMIT 10;

-- Çeki listesinden gönderilen kayıtları göster
SELECT 
  id,
  model_id,
  adet,
  gonderim_durumu,
  gonderim_tarihi
FROM ceki_listesi
WHERE gonderim_durumu = 'gonderildi'
ORDER BY gonderim_tarihi DESC
LIMIT 10;
