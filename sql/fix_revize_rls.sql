-- Revize işlemi için RLS politikalarını düzelt

-- 1. Mevcut dokuma_atamalari RLS politikalarını kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'dokuma_atamalari';

-- 2. Geçici olarak RLS'yi kapat (test için)
ALTER TABLE dokuma_atamalari DISABLE ROW LEVEL SECURITY;

-- 3. Test: ID 25'i manuel güncelle
UPDATE dokuma_atamalari 
SET tamamlanan_adet = 100, durum = 'tamamlandi'
WHERE id = 25;

-- 4. Sonucu kontrol et
SELECT id, durum, tamamlanan_adet, kabul_edilen_adet, tedarikci_id
FROM dokuma_atamalari 
WHERE id = 25;

-- 5. RLS'yi tekrar aç
ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;

-- 6. Tedarikci tablosundan kullanıcı bilgisini al
SELECT id, email, sirket FROM tedarikciler WHERE email LIKE '%volkan%' OR sirket LIKE '%Volkan%';