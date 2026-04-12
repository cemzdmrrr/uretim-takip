-- Model bd7fe943-20f4-4814-a7bf-3e00e8bb67c0 için Konfeksiyon verisini kontrol et

-- 1. Konfeksiyon atama_id'sini bul
SELECT id, model_id, durum FROM konfeksiyon_atamalari 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0'::UUID
LIMIT 1;

-- 2. Konfeksiyon beden takip tablosunda bu model'in verileri var mı?
SELECT * FROM konfeksiyon_beden_takip 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0'::UUID;

-- 3. SQL fonksiyonunu test et
SELECT * FROM get_onceki_asama_gerceklesen_adetler(
  'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0',
  'konfeksiyon'
);

-- Beklenen sonuç:
-- S: 80 (90 - 10)
-- M: 50 (50 - 0)
-- L: 50 (50 - 0)
