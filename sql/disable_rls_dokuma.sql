-- RLS'yi geçici olarak kapat ve revize işlemini test et

-- 1. Mevcut RLS durumunu kontrol et
SELECT schemaname, tablename, rowsecurity, policyname 
FROM information_schema.tables t
LEFT JOIN pg_policies p ON p.tablename = t.table_name
WHERE t.table_name = 'dokuma_atamalari';

-- 2. RLS'yi kapat
ALTER TABLE dokuma_atamalari DISABLE ROW LEVEL SECURITY;

-- 3. Test güncellemesi yap
SELECT id, durum, tamamlanan_adet, kabul_edilen_adet
FROM dokuma_atamalari 
WHERE id = 25;

-- 4. Manual güncelleme testi
UPDATE dokuma_atamalari 
SET tamamlanan_adet = 100, durum = 'tamamlandi'
WHERE id = 25;

-- 5. Sonucu kontrol et
SELECT id, durum, tamamlanan_adet, kabul_edilen_adet
FROM dokuma_atamalari 
WHERE id = 25;

-- 6. RLS'yi tekrar aç (test bittikten sonra)
-- ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;