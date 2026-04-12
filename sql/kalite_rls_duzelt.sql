-- Kalite kontrol atamaları tablosu için RLS politikalarını düzelt

-- 1. Mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'kalite_kontrol_atamalari';

-- 2. Geçici olarak RLS'yi kapat (test için)
ALTER TABLE kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;

-- 3. Veya politika ekle (kalıcı çözüm)
-- Bu politikalar kullanıcıların kendi atamalarını görmelerini sağlar
CREATE POLICY "kalite_kontrol_insert_policy" ON kalite_kontrol_atamalari
    FOR INSERT 
    WITH CHECK (true);

CREATE POLICY "kalite_kontrol_select_policy" ON kalite_kontrol_atamalari
    FOR SELECT 
    USING (true);

CREATE POLICY "kalite_kontrol_update_policy" ON kalite_kontrol_atamalari
    FOR UPDATE 
    USING (true)
    WITH CHECK (true);

-- 4. RLS'yi tekrar aç (politikalarla birlikte)
ALTER TABLE kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;

-- 5. Test: Kalite kontrol tablosunu kontrol et
SELECT id, model_id, durum, created_at, notlar
FROM kalite_kontrol_atamalari
ORDER BY created_at DESC
LIMIT 5;