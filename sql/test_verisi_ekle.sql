-- Test verisi ekleme

-- 1. Ana klasör oluştur
INSERT INTO dosyalar (
    ad, 
    dosya_turu, 
    yol, 
    ust_klasor_id, 
    aciklama,
    olusturan_kullanici_id,
    aktif,
    genel_erisim
) VALUES 
(
    'Ana Klasör', 
    'folder', 
    '/ana-klasor', 
    NULL, 
    'Ana dosya klasörü',
    (SELECT id FROM auth.users LIMIT 1),
    true,
    true
);

-- 2. Alt klasör oluştur
INSERT INTO dosyalar (
    ad, 
    dosya_turu, 
    yol, 
    ust_klasor_id, 
    aciklama,
    olusturan_kullanici_id,
    aktif,
    genel_erisim
) VALUES 
(
    'Belgeler', 
    'folder', 
    '/ana-klasor/belgeler', 
    (SELECT id FROM dosyalar WHERE ad = 'Ana Klasör' LIMIT 1), 
    'Belge klasörü',
    (SELECT id FROM auth.users LIMIT 1),
    true,
    false
);

-- 3. Test dosyası oluştur
INSERT INTO dosyalar (
    ad, 
    dosya_turu, 
    yol, 
    ust_klasor_id, 
    aciklama,
    olusturan_kullanici_id,
    boyut,
    mime_type,
    aktif,
    genel_erisim
) VALUES 
(
    'test-dosyasi.pdf', 
    'pdf', 
    '/ana-klasor/belgeler/test-dosyasi.pdf', 
    (SELECT id FROM dosyalar WHERE ad = 'Belgeler' LIMIT 1), 
    'Test PDF dosyası',
    (SELECT id FROM auth.users LIMIT 1),
    1024000,
    'application/pdf',
    true,
    false
);

-- Kontrol
SELECT 
    ad,
    dosya_turu,
    yol,
    ust_klasor_id,
    genel_erisim
FROM dosyalar 
ORDER BY olusturma_tarihi;
