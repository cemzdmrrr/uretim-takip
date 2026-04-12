-- Database yapısını kontrol et

-- 1. iplik_teslimat_kayitlari tablosunun kolonlarını listele
SELECT 'iplik_teslimat_kayitlari columns:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'iplik_teslimat_kayitlari' 
ORDER BY ordinal_position;

-- 2. Foreign key constraint'leri kontrol et
SELECT 'Foreign key constraints:' as info;
SELECT
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'iplik_teslimat_kayitlari';

-- 3. Tüm tabloları listele
SELECT 'Available tables:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
