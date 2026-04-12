-- ALTERNATIF ÇÖZÜM: Constraint'i tamamen kaldırıp yeniden ekleyelim

-- 1. Tüm constraint'leri göster
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'dokuma_atamalari';

-- 2. durum ile ilgili constraint'leri bul
SELECT constraint_name, check_clause
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%dokuma%';

-- 3. Mevcut constraint'i kaldır (exact name bulunca)
-- Bu komutları tek tek çalıştır
DO $$ 
BEGIN
    -- Constraint var mı kontrol et ve kaldır
    IF EXISTS (
        SELECT 1 FROM information_schema.check_constraints 
        WHERE constraint_name = 'dokuma_atamalari_durum_check'
    ) THEN
        ALTER TABLE dokuma_atamalari DROP CONSTRAINT dokuma_atamalari_durum_check;
    END IF;
END $$;

-- 4. Yeni constraint ekle
ALTER TABLE dokuma_atamalari 
ADD CONSTRAINT dokuma_atamalari_durum_check 
CHECK (durum = ANY (ARRAY['atandi'::text, 'onaylandi'::text, 'baslatildi'::text, 'tamamlandi'::text, 'iptal'::text, 'uretimde'::text, 'reddedildi'::text, 'kismi_tamamlandi'::text]));

-- 5. Eksik sütunları ekle
ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS onay_tarihi TIMESTAMP WITH TIME ZONE;

ALTER TABLE dokuma_atamalari 
ADD COLUMN IF NOT EXISTS kabul_edilen_adet INTEGER;

-- 6. Test güncelleme
UPDATE dokuma_atamalari 
SET durum = 'onaylandi', onay_tarihi = NOW(), kabul_edilen_adet = 100
WHERE id = 25;

-- 7. Sonucu kontrol et
SELECT id, model_id, durum, onay_tarihi, kabul_edilen_adet, tedarikci_id, created_at
FROM dokuma_atamalari 
WHERE id = 25;