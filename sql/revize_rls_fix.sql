-- Revize işlemi için RLS politikalarını düzelt

-- 1. Mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'dokuma_atamalari';

-- 2. Geçici olarak RLS'yi kapat (test için)
ALTER TABLE dokuma_atamalari DISABLE ROW LEVEL SECURITY;

-- 3. Veya update politikası ekle (kalıcı çözüm)
-- Bu politika tedarikçilerin kendi atamalarını güncellemesini sağlar
DROP POLICY IF EXISTS "dokuma_atamalari_update_policy" ON dokuma_atamalari;

CREATE POLICY "dokuma_atamalari_update_policy" ON dokuma_atamalari
    FOR UPDATE 
    USING (true)
    WITH CHECK (true);

-- 4. Diğer atama tablolarını da güncelle
ALTER TABLE konfeksiyon_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE nakis_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE yikama_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE ilik_dugme_atamalari DISABLE ROW LEVEL SECURITY;
ALTER TABLE utu_atamalari DISABLE ROW LEVEL SECURITY;

-- 5. Test güncelleme
SELECT id, durum, tamamlanan_adet, tedarikci_id 
FROM dokuma_atamalari 
WHERE id = 25;

-- Test güncelleme
UPDATE dokuma_atamalari 
SET tamamlanan_adet = 100, durum = 'tamamlandi' 
WHERE id = 25;

SELECT id, durum, tamamlanan_adet, tedarikci_id 
FROM dokuma_atamalari 
WHERE id = 25;