-- user_roles tablosundaki role constraint'ini kontrol et
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_type
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_name = 'user_roles_role_check';

-- Ayrıca check constraint'in detaylarını göster
SELECT 
    pgc.conname AS constraint_name,
    pgc.consrc AS constraint_definition
FROM 
    pg_constraint pgc
    JOIN pg_class pgcl ON pgcl.oid = pgc.conrelid
    JOIN pg_namespace nsp ON nsp.oid = pgcl.relnamespace
WHERE 
    pgcl.relname = 'user_roles' 
    AND pgc.contype = 'c'
    AND pgc.conname = 'user_roles_role_check';
