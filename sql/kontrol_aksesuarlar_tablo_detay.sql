-- Aksesuarlar tablosunun mevcut yapısını kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'aksesuarlar' 
ORDER BY ordinal_position;

-- Tablonun var olup olmadığını kontrol et
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_name = 'aksesuarlar'
);

-- Mevcut tabloları listele
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
