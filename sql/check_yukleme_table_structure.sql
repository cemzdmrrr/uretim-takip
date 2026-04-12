-- Yukleme kayitlari tablosunun yapısını kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
ORDER BY ordinal_position;

-- Ceki listesi tablosunun yapısını kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ceki_listesi'
ORDER BY ordinal_position;

-- Modeller tablosunun yapısını kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'modeller'
ORDER BY ordinal_position;
