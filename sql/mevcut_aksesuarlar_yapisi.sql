-- Mevcut aksesuarlar tablosunun tam yapısını kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'aksesuarlar'
ORDER BY ordinal_position;

-- Tablo içeriğini de kontrol et (ilk birkaç kayıt)
SELECT * FROM public.aksesuarlar LIMIT 5;
