-- PersonelDetayPage hatalarını çözmek için veri tiplerini kontrol et

-- 1. Tüm tablolardaki personel_id tiplerini kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'personel_id'
ORDER BY table_name;

-- 2. odeme_kayitlari tablosundaki tüm sütunları kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'odeme_kayitlari'
ORDER BY ordinal_position;

-- 3. personel_arsiv tablosundaki sütunları kontrol et
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'personel_arsiv'
ORDER BY ordinal_position;

-- 4. donemler tablosunda tekrar eden değerleri kontrol et
SELECT 
    kod,
    COUNT(*) as adet,
    STRING_AGG(ad, ' | ') as adlar
FROM public.donemler 
GROUP BY kod 
HAVING COUNT(*) > 1;

-- 5. Mevcut veri durumunu kontrol et
SELECT 'odeme_kayitlari' as tablo, COUNT(*) as kayit_sayisi FROM public.odeme_kayitlari
UNION ALL
SELECT 'personel_arsiv' as tablo, COUNT(*) as kayit_sayisi FROM public.personel_arsiv
UNION ALL
SELECT 'donemler' as tablo, COUNT(*) as kayit_sayisi FROM public.donemler;
