-- STORAGE TEST DOSYALARI EKLEYİCİ

-- Test dosyaları için dummy data oluşturucu
-- Bu dosyalar Storage'da olmadığı için URL açılmayacak
-- Gerçek dosya upload'ı test etmek için uygulamadan dosya yükleyin

-- Önce güncel test verilerini ekle
DELETE FROM dosya_paylasimlari;
DELETE FROM dosyalar;

-- 1. Test klasörü
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
    NULL,
    true,
    true
);

-- 2. Ana dosyalar klasörü
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
    'folders/belgeler', 
    NULL, 
    'Ana belgeler klasörü',
    NULL,
    true,
    true
);

-- NOT: Gerçek dosya testleri için uygulamadan dosya yükleyin
-- Bu test verileri sadece klasör yapısını gösterir

SELECT 
    id,
    ad,
    dosya_turu,
    yol,
    aktif
FROM dosyalar 
ORDER BY olusturma_tarihi;
