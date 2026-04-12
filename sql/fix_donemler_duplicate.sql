-- ADIM 4: donemler tablosundaki tekrarlayan kayıtları temizle

-- Önce tekrarlayan kayıtları kontrol et
SELECT 
    kod,
    COUNT(*) as adet,
    STRING_AGG(ad, ' | ') as adlar
FROM public.donemler 
GROUP BY kod 
HAVING COUNT(*) > 1;

-- Tekrarlayan kayıtları temizle (sadece en eskisini tut)
DELETE FROM public.donemler 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM public.donemler 
    GROUP BY kod
);

-- Benzersizlik constraint'i ekle (güvenli şekilde)
DO $$
BEGIN
    -- Constraint'in varlığını kontrol et ve yoksa ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'donemler' 
        AND constraint_name = 'donemler_kod_unique'
        AND constraint_type = 'UNIQUE'
    ) THEN
        ALTER TABLE public.donemler ADD CONSTRAINT donemler_kod_unique UNIQUE (kod);
        RAISE NOTICE 'donemler_kod_unique constraint eklendi';
    ELSE
        RAISE NOTICE 'donemler_kod_unique constraint zaten mevcut';
    END IF;
END $$;

-- Sonucu kontrol et
SELECT COUNT(*) as toplam_donem, COUNT(DISTINCT kod) as benzersiz_kod FROM public.donemler;
