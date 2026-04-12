-- TABLO YAPISI KONTROLÜ
-- Bu sorguları önce çalıştırıp mevcut durumu kontrol edin

-- 1. Tablo var mı?
SELECT 'uretim_kayitlari tablosu mevcut mu?' as kontrol,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_name = 'uretim_kayitlari'
       ) THEN 'EVET' ELSE 'HAYIR' END as sonuc;

-- 2. Mevcut sütunlar
SELECT 'Mevcut sütunlar:' as baslik;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'uretim_kayitlari'
ORDER BY ordinal_position;

-- 3. Mevcut constraint'ler
SELECT 'Mevcut constraint''ler:' as baslik;
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'uretim_kayitlari';

-- 4. Sequence var mı?
SELECT 'Sequence kontrolü:' as baslik;
SELECT 
    schemaname,
    sequencename,
    start_value,
    increment_by
FROM pg_sequences 
WHERE sequencename LIKE '%uretim_kayitlari%';

-- 5. Mevcut kayıt sayısı ve durumlar
SELECT 'Mevcut kayıtlar:' as baslik;
SELECT 
    durum,
    COUNT(*) as adet
FROM uretim_kayitlari 
GROUP BY durum
ORDER BY durum;
