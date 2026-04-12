-- BASİT TEST VERİSİ - AUTH OLMADAN

-- Önce mevcut verileri sil
DELETE FROM dosya_paylasimlari;
DELETE FROM dosyalar;

-- 1. Test klasörü (auth.uid() olmadan)
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
    'Test Klasörü', 
    'folder', 
    'folders/test-klasoru', 
    NULL, 
    'Test için oluşturulan klasör',
    NULL,  -- Auth olmadan test
    true,
    true   -- Herkese açık
);

-- 2. Test dosyası
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
    'test.pdf', 
    'pdf', 
    'files/1640995200000_test.pdf', 
    (SELECT id FROM dosyalar WHERE ad = 'Test Klasörü' LIMIT 1), 
    'Test PDF dosyası',
    NULL,  -- Auth olmadan test
    1048576,  -- 1MB
    'application/pdf',
    true,
    true   -- Herkese açık
);

-- 3. Test dosyası 2
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
    'rapor.docx', 
    'docx', 
    'files/1640995300000_rapor.docx', 
    (SELECT id FROM dosyalar WHERE ad = 'Test Klasörü' LIMIT 1), 
    'Test Word dosyası',
    NULL,  -- Auth olmadan test
    2048576,  -- 2MB
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    true,
    true   -- Herkese açık
);

-- Kontrol
SELECT 
    id,
    ad,
    dosya_turu,
    yol,
    ust_klasor_id,
    genel_erisim,
    aktif
FROM dosyalar 
ORDER BY olusturma_tarihi;
