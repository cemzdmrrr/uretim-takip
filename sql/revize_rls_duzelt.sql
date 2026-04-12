-- Revize işlemi için RLS politikalarını düzelt

-- 1. Dokuma atamaları için RLS politikalarını kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'dokuma_atamalari';

-- 2. Geçici olarak RLS'yi kapat (test için)
ALTER TABLE dokuma_atamalari DISABLE ROW LEVEL SECURITY;

-- 3. Veya güncelleme politikası ekle (kalıcı çözüm)
CREATE POLICY "dokuma_update_policy" ON dokuma_atamalari
    FOR UPDATE 
    USING (true)
    WITH CHECK (true);

-- 4. RLS'yi tekrar aç (politikalarla birlikte)
-- ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;

-- 5. Test: Dokuma atamaları tablosunu kontrol et
SELECT id, durum, tamamlanan_adet, tedarikci_id
FROM dokuma_atamalari
WHERE id = 25;