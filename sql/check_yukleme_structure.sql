-- Yukleme kayitlari tablosunun yapısı
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'yukleme_kayitlari'
ORDER BY ordinal_position;
