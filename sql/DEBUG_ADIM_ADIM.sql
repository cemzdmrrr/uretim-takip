-- ==========================================
-- STEP-BY-STEP DEBUG
-- ==========================================

-- 1. Bu model'in beden dağılımı
SELECT * FROM model_beden_dagilimi 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0';

-- 2. Dokuma adet transfer fonksiyonunu test et
SELECT * FROM get_onceki_asama_gerceklesen_adetler(
  'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0'::TEXT,
  'konfeksiyon'
);

-- Beklenen sonuç: S, M, L beden adetleri (produce - fire)

-- 3. Konfeksiyon tablosunda bu model var mı?
SELECT * FROM konfeksiyon_beden_takip 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0';

-- 4. Konfeksiyon atama_id nedir?
SELECT id, model_id, durum FROM konfeksiyon_atamalari 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0'
LIMIT 1;

-- 5. Dokuma'dan Konfeksiyon'a adet transfer fonksiyonunu çalıştır
-- (Önceki 4. soruda atama_id'yi kopyala, aşağıya yapıştır)
SELECT update_sonraki_asama_hedef_adetler(
  'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0'::UUID,
  'dokuma',
  52  -- konfeksiyon_atamalari.id (varsa)
);

-- 6. Sonra konfeksiyon tablosunu kontrol et
SELECT * FROM konfeksiyon_beden_takip 
WHERE model_id = 'bd7fe943-20f4-4814-a7bf-3e00e8bb67c0';
