-- Modeller tablosunun yapısını kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'modeller' 
AND column_name = 'id'
ORDER BY ordinal_position;

-- Model kritikleri tablosu var mı kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'model_kritikleri'
ORDER BY ordinal_position;