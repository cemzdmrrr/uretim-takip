-- SADECE BUCKET OLUŞTURMA

-- Dosyalar bucket'ını oluştur
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
ON CONFLICT (id) DO NOTHING;

-- Kontrol
SELECT id, name, public FROM storage.buckets WHERE id = 'dosyalar';
