-- SUPABASE STORAGE POLİTİKALARI

-- 1. ÖNCE STORAGE BUCKET'INI KONTROL ET
SELECT name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE name = 'dosyalar';

-- Eğer bucket yoksa oluştur
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'dosyalar', 
    'dosyalar', 
    false, 
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
ON CONFLICT (id) DO NOTHING;

-- 2. STORAGE OBJECTS İÇİN POLİTİKALAR

-- Mevcut storage politikalarını sil
DROP POLICY IF EXISTS "dosyalar_upload_policy" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_select_policy" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_update_policy" ON storage.objects;
DROP POLICY IF EXISTS "dosyalar_delete_policy" ON storage.objects;

-- UPLOAD POLİTİKASI - Herkes upload edebilir
CREATE POLICY "dosyalar_upload_policy" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'dosyalar' AND 
        auth.uid() IS NOT NULL
    );

-- SELECT POLİTİKASI - Herkes görebilir (geçici test için)
CREATE POLICY "dosyalar_select_policy" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'dosyalar');

-- UPDATE POLİTİKASI - Sadece upload eden güncelleyebilir
CREATE POLICY "dosyalar_update_policy" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'dosyalar' AND 
        owner = auth.uid()
    );

-- DELETE POLİTİKASI - Sadece upload eden silebilir
CREATE POLICY "dosyalar_delete_policy" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'dosyalar' AND 
        owner = auth.uid()
    );

-- Kontrol
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';
