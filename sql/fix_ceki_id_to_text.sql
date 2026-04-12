-- ceki_id sütununu UUID'den text'e çevir
ALTER TABLE yukleme_kayitlari 
ALTER COLUMN ceki_id TYPE text USING ceki_id::text;

-- Kontrol et
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
  AND column_name IN ('model_id', 'ceki_id')
ORDER BY column_name;
