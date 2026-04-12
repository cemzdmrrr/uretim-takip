-- Dokuma atamaları tablosuna adet kolonu ekleme
-- Mevcut tablo yapısını kontrol edelim

-- 1. Önce mevcut tabloyu kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari'
ORDER BY ordinal_position;

-- 2. Eğer adet kolonu yoksa ekle
DO $$
BEGIN
    -- Adet kolonu var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dokuma_atamalari' 
        AND column_name = 'adet'
    ) THEN
        -- Adet kolonu ekle
        ALTER TABLE dokuma_atamalari 
        ADD COLUMN adet INTEGER;
        
        RAISE NOTICE 'Adet kolonu dokuma_atamalari tablosuna eklendi';
    ELSE
        RAISE NOTICE 'Adet kolonu zaten mevcut';
    END IF;
    
    -- Talep_edilen_adet kolonu var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dokuma_atamalari' 
        AND column_name = 'talep_edilen_adet'
    ) THEN
        -- Talep edilen adet kolonu ekle
        ALTER TABLE dokuma_atamalari 
        ADD COLUMN talep_edilen_adet INTEGER;
        
        RAISE NOTICE 'Talep_edilen_adet kolonu dokuma_atamalari tablosuna eklendi';
    ELSE
        RAISE NOTICE 'Talep_edilen_adet kolonu zaten mevcut';
    END IF;
    
    -- Tamamlanan_adet kolonu var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dokuma_atamalari' 
        AND column_name = 'tamamlanan_adet'
    ) THEN
        -- Tamamlanan adet kolonu ekle (NULL kabul eder)
        ALTER TABLE dokuma_atamalari 
        ADD COLUMN tamamlanan_adet INTEGER;
        
        RAISE NOTICE 'Tamamlanan_adet kolonu dokuma_atamalari tablosuna eklendi';
    ELSE
        RAISE NOTICE 'Tamamlanan_adet kolonu zaten mevcut';
    END IF;
    
    -- Musteri_adi kolonu var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'dokuma_atamalari' 
        AND column_name = 'musteri_adi'
    ) THEN
        -- Müşteri adı kolonu ekle
        ALTER TABLE dokuma_atamalari 
        ADD COLUMN musteri_adi TEXT;
        
        RAISE NOTICE 'Musteri_adi kolonu dokuma_atamalari tablosuna eklendi';
    ELSE
        RAISE NOTICE 'Musteri_adi kolonu zaten mevcut';
    END IF;
END $$;

-- 3. Güncellenmiş tablo yapısını göster
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'dokuma_atamalari'
ORDER BY ordinal_position;

-- 4. Mevcut kayıtlar için varsayılan değerler ayarla
UPDATE dokuma_atamalari 
SET 
    adet = COALESCE(adet, 1),
    talep_edilen_adet = COALESCE(talep_edilen_adet, 1)
WHERE adet IS NULL OR talep_edilen_adet IS NULL;

COMMIT;