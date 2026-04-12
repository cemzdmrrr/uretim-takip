-- ATAMA TABLOLARI DÜZELTME
-- Bu SQL'i Supabase SQL Editor'de çalıştırın

-- 1. Önce duplicate kayıtları temizle (her model için sadece en son kaydı tut)
-- Dokuma atamaları
DELETE FROM dokuma_atamalari a
USING dokuma_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;

-- Konfeksiyon atamaları
DELETE FROM konfeksiyon_atamalari a
USING konfeksiyon_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;

-- Yıkama atamaları
DELETE FROM yikama_atamalari a
USING yikama_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;

-- Nakış atamaları
DELETE FROM nakis_atamalari a
USING nakis_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;

-- Ütü atamaları
DELETE FROM utu_atamalari a
USING utu_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;

-- İlik düğme atamaları
DELETE FROM ilik_dugme_atamalari a
USING ilik_dugme_atamalari b
WHERE a.model_id = b.model_id 
  AND a.id < b.id;


-- 2. Unique constraint ekle (yoksa)
-- Dokuma
ALTER TABLE dokuma_atamalari DROP CONSTRAINT IF EXISTS dokuma_atamalari_model_id_key;
ALTER TABLE dokuma_atamalari ADD CONSTRAINT dokuma_atamalari_model_id_key UNIQUE (model_id);

-- Konfeksiyon
ALTER TABLE konfeksiyon_atamalari DROP CONSTRAINT IF EXISTS konfeksiyon_atamalari_model_id_key;
ALTER TABLE konfeksiyon_atamalari ADD CONSTRAINT konfeksiyon_atamalari_model_id_key UNIQUE (model_id);

-- Yıkama
ALTER TABLE yikama_atamalari DROP CONSTRAINT IF EXISTS yikama_atamalari_model_id_key;
ALTER TABLE yikama_atamalari ADD CONSTRAINT yikama_atamalari_model_id_key UNIQUE (model_id);

-- Nakış
ALTER TABLE nakis_atamalari DROP CONSTRAINT IF EXISTS nakis_atamalari_model_id_key;
ALTER TABLE nakis_atamalari ADD CONSTRAINT nakis_atamalari_model_id_key UNIQUE (model_id);

-- Ütü
ALTER TABLE utu_atamalari DROP CONSTRAINT IF EXISTS utu_atamalari_model_id_key;
ALTER TABLE utu_atamalari ADD CONSTRAINT utu_atamalari_model_id_key UNIQUE (model_id);

-- İlik düğme
ALTER TABLE ilik_dugme_atamalari DROP CONSTRAINT IF EXISTS ilik_dugme_atamalari_model_id_key;
ALTER TABLE ilik_dugme_atamalari ADD CONSTRAINT ilik_dugme_atamalari_model_id_key UNIQUE (model_id);


-- 3. Eksik kolonları ekle (tedarikci_id yoksa)
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
ALTER TABLE nakis_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;


-- 4. Sonuçları kontrol et
SELECT 'dokuma_atamalari' as tablo, COUNT(*) as kayit_sayisi FROM dokuma_atamalari
UNION ALL
SELECT 'konfeksiyon_atamalari', COUNT(*) FROM konfeksiyon_atamalari
UNION ALL
SELECT 'yikama_atamalari', COUNT(*) FROM yikama_atamalari
UNION ALL
SELECT 'nakis_atamalari', COUNT(*) FROM nakis_atamalari
UNION ALL
SELECT 'utu_atamalari', COUNT(*) FROM utu_atamalari;

-- Constraint'leri kontrol et
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_name LIKE '%_atamalari'
  AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name;
