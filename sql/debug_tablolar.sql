-- TABLOLARIN GERÇEK DURUMUNU KONTROL ET

-- 1. Hangi tablolar var?
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%dosya%' 
ORDER BY table_name;

-- 2. Dosyalar tablosunun sütunları
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'dosyalar' 
ORDER BY ordinal_position;

-- 3. Dosya paylaşımları tablosunun sütunları
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'dosya_paylasimlari' 
ORDER BY ordinal_position;

-- 4. Mevcut politikalar
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename LIKE '%dosya%'
ORDER BY tablename, policyname;

-- 5. RLS durumu
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename LIKE '%dosya%';
