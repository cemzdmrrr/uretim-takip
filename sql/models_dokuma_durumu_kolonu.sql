-- Models tablosuna dokuma durumu kolonu ekle (eğer yoksa)
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='dokuma_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN dokuma_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (dokuma_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;
END $$;

-- İndeks ekle
CREATE INDEX IF NOT EXISTS idx_modeller_dokuma_durumu ON modeller(dokuma_durumu);

-- Mevcut kayıtları güncelle
UPDATE modeller SET dokuma_durumu = 'bekliyor' WHERE dokuma_durumu IS NULL;

-- Kontrol sorgusu
SELECT 
    'modeller' as tablo,
    COUNT(*) as toplam_kayit,
    COUNT(CASE WHEN dokuma_durumu = 'bekliyor' THEN 1 END) as bekleyen,
    COUNT(CASE WHEN dokuma_durumu = 'atandi' THEN 1 END) as atandi,
    COUNT(CASE WHEN dokuma_durumu = 'onaylandi' THEN 1 END) as onaylandi,
    COUNT(CASE WHEN dokuma_durumu = 'uretimde' THEN 1 END) as uretimde,
    COUNT(CASE WHEN dokuma_durumu = 'tamamlandi' THEN 1 END) as tamamlandi
FROM modeller;
