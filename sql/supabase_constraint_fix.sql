-- TEDARIKCI CONSTRAINT HATASI ÇÖZÜMÜ
-- Bu SQL'i Supabase Dashboard'da çalıştırın

-- 1. Mevcut constraint'leri kontrol edin
SELECT conname, contype, pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'tedarikciler'::regclass 
  AND contype = 'c'
  AND conname LIKE '%faaliyet%';

-- 2. Faaliyet constraint'ini kaldırın
ALTER TABLE tedarikciler DROP CONSTRAINT IF EXISTS tedarikciler_faaliyet_check;

-- 3. Diğer olası constraint'leri kaldırın
ALTER TABLE tedarikciler DROP CONSTRAINT IF EXISTS tedarikciler_tedarikci_tipi_check;
ALTER TABLE tedarikciler DROP CONSTRAINT IF EXISTS tedarikciler_durum_check;

-- 4. Test kaydı ekleyin
INSERT INTO tedarikciler (
    ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum, vergi_no, tc_kimlik, iban_no
) VALUES (
    'Test', 'Kullanıcı', 'Test Şirketi', '05551234567', 'test@test.com', 
    'Üretici', 'konf', 'aktif', '1234567890', '12345678901', 'TR330006100519786457841326'
);

-- 5. Başarı mesajı
SELECT 'Constraint hatası çözüldü! Artık serbest text girebilirsiniz.' as mesaj;
