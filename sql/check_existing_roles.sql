-- Database'deki mevcut rolleri kontrol et
SELECT DISTINCT role FROM user_roles ORDER BY role;

-- user_roles tablosunun yapısını kontrol et
\d user_roles;

-- Constraint detaylarını göster
SELECT conname, consrc 
FROM pg_constraint 
WHERE conrelid = 'user_roles'::regclass 
AND contype = 'c';

-- Alternatif constraint detayı
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'user_roles' 
AND tc.constraint_type = 'CHECK';
