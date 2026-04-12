-- Ceki_listesi id tipini kontrol et
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'ceki_listesi'
  AND column_name = 'id';

-- Yukleme kayitlari ceki_id tipini kontrol et
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
  AND column_name = 'ceki_id';
