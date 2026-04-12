-- ÖNCE TABLOLARIN DURUMUNU KONTROL ET

-- 1. Dosyalar tablosunun sütunlarını listele
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'dosyalar' 
ORDER BY ordinal_position;

-- 2. Dosya paylaşımları tablosunun sütunlarını listele
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'dosya_paylasimlari' 
ORDER BY ordinal_position;

-- 3. Mevcut tabloları listele
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_name IN ('dosyalar', 'dosya_paylasimlari');

-- 4. Mevcut politikaları listele
SELECT tablename, policyname, cmd
FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari');
