-- Database verification script
-- Run this after executing the comprehensive schema to verify all tables exist

-- Check all tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check if all required tables for the Flutter app exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'musteriler' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS musteriler_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tedarikci' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS tedarikci_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'faturalar' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS faturalar_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'personel' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS personel_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'triko_takip' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS triko_takip_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stok_hareketi' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS stok_hareketi_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kasa_banka' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS kasa_banka_table,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kasa_banka_hareketleri' AND table_schema = 'public') THEN 'EXISTS'
        ELSE 'MISSING'
    END AS kasa_banka_hareketleri_table;

-- Check if the view exists
SELECT 
    table_name,
    table_type
FROM information_schema.views 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Test the view
SELECT * FROM musteri_siparis_ozet LIMIT 5;

-- Check data exists in key tables
SELECT 
    'musteriler' as table_name,
    COUNT(*) as row_count
FROM musteriler
UNION ALL
SELECT 
    'tedarikci' as table_name,
    COUNT(*) as row_count
FROM tedarikci
UNION ALL
SELECT 
    'faturalar' as table_name,
    COUNT(*) as row_count
FROM faturalar
UNION ALL
SELECT 
    'personel' as table_name,
    COUNT(*) as row_count
FROM personel
UNION ALL
SELECT 
    'triko_takip' as table_name,
    COUNT(*) as row_count
FROM triko_takip
ORDER BY table_name;
