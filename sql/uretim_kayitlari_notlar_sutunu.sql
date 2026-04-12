-- uretim_kayitlari tablosuna notlar sütunu ekleme
-- Bu dosya notlar sütununun eksik olması durumunda çalıştırılmalıdır

-- notlar sütununu ekle (eğer yoksa)
DO $$
BEGIN
    -- notlar sütunu var mı kontrol et
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'notlar'
    ) THEN
        -- notlar sütununu ekle
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN notlar TEXT;
        
        RAISE NOTICE 'notlar sütunu başarıyla eklendi';
    ELSE
        RAISE NOTICE 'notlar sütunu zaten mevcut';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'notlar sütunu ekleme hatası: %', SQLERRM;
END $$;

-- Mevcut kayıtlar için varsayılan notlar ekle
UPDATE uretim_kayitlari 
SET notlar = 'Mevcut kayıt' 
WHERE notlar IS NULL;

-- Tablo yapısını kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'uretim_kayitlari' 
ORDER BY ordinal_position;
