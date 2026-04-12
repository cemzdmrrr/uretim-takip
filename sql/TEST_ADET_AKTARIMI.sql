-- ==========================================
-- ADET AKTARIMI TEST SCRIPTI
-- ==========================================

-- 1. Dokuma'da test verisi ekle
-- Bir modeli seç (UUID kopiala) veya yenisini kullan
-- Örnek: model UUID = 'test-model-001'

-- 2. Dokuma aşamasına üretim verisi ekle
-- Önce bir dokuma ataması bul veya kendi atama_id'ni kullan
INSERT INTO dokuma_beden_takip (atama_id, model_id, beden_kodu, hedef_adet, uretilen_adet, fire_adet, kayit_tarihi)
VALUES 
  ((SELECT id::UUID FROM dokuma_atamalari LIMIT 1), (SELECT id::UUID FROM modeller LIMIT 1), 'S', 300, 100, 20, NOW()),
  ((SELECT id::UUID FROM dokuma_atamalari LIMIT 1), (SELECT id::UUID FROM modeller LIMIT 1), 'M', 300, 100, 0, NOW()),
  ((SELECT id::UUID FROM dokuma_atamalari LIMIT 1), (SELECT id::UUID FROM modeller LIMIT 1), 'L', 300, 100, 0, NOW())
ON CONFLICT (atama_id, beden_kodu) DO UPDATE SET 
  uretilen_adet = EXCLUDED.uretilen_adet,
  fire_adet = EXCLUDED.fire_adet;

-- 3. SQL fonksiyonunu test et
SELECT * FROM get_onceki_asama_gerceklesen_adetler(
  (SELECT id::TEXT FROM modeller LIMIT 1),
  'konfeksiyon'
);

-- Sonuç:
-- S: 80 (100 - 20)
-- M: 100 (100 - 0)
-- L: 100 (100 - 0)
-- TOPLAM: 280 (300 - 20)

-- 4. Konfeksiyon ataması kontrol et (veya yeni atama ekle)
SELECT * FROM konfeksiyon_atamalari 
WHERE model_id = (SELECT id::UUID FROM modeller LIMIT 1)
LIMIT 1;

-- 5. Konfeksiyon hedef adetlerini güncelle
SELECT update_sonraki_asama_hedef_adetler(
  (SELECT id::UUID FROM modeller LIMIT 1),
  'dokuma',
  (SELECT id::UUID FROM konfeksiyon_atamalari WHERE model_id = (SELECT id::UUID FROM modeller LIMIT 1) LIMIT 1)
);

-- 6. Sonucu kontrol et
SELECT * FROM konfeksiyon_beden_takip
WHERE model_id = (SELECT id::UUID FROM modeller LIMIT 1);

-- Sonuç:
-- S: 80
-- M: 100
-- L: 100
