-- 1. Önce mevcut verileri kontrol et
SELECT COUNT(*) as mevcut_kayit_sayisi FROM yukleme_kayitlari;

-- 2. Eğer veri varsa temizle (opsiyonel - emin olun!)
-- TRUNCATE TABLE yukleme_kayitlari;

-- 3. model_id sütununu UUID'den text'e çevir (daha esnek)
ALTER TABLE yukleme_kayitlari 
ALTER COLUMN model_id TYPE text USING model_id::text;

-- 4. Kontrol et
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
  AND column_name = 'model_id';
