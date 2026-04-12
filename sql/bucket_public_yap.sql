-- BUCKET'I PUBLIC YAP

-- Dosyalar bucket'ını public yap
UPDATE storage.buckets 
SET public = true 
WHERE id = 'dosyalar';

-- Kontrol
SELECT id, name, public FROM storage.buckets WHERE id = 'dosyalar';
