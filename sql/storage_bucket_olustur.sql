-- STORAGE BUCKET OLUŞTURMA

-- 1. Mevcut bucket'ları kontrol et
SELECT id, name, public, created_at 
FROM storage.buckets;

-- 2. Dosyalar bucket'ını oluştur
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'dosyalar',
    'dosyalar', 
    false,  -- Private bucket
    52428800,  -- 50MB limit
    ARRAY[
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel', 
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'image/jpeg',
        'image/png',
        'image/gif',
        'text/plain'
    ]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. Storage için RLS politikaları (önce sil, sonra oluştur)
DROP POLICY IF EXISTS "dosyalar_bucket_select" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_bucket_insert" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_bucket_update" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_bucket_delete" ON storage.objects;

CREATE POLICY "dosyalar_bucket_select" ON storage.objects
    FOR SELECT USING (bucket_id = 'dosyalar');

CREATE POLICY "dosyalar_bucket_insert" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'dosyalar');

CREATE POLICY "dosyalar_bucket_update" ON storage.objects
    FOR UPDATE USING (bucket_id = 'dosyalar');

CREATE POLICY "dosyalar_bucket_delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'dosyalar');

-- Kontrol
SELECT 'Storage bucket başarıyla oluşturuldu!' as mesaj;
SELECT id, name, public FROM storage.buckets WHERE id = 'dosyalar';
