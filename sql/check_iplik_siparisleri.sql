-- ÖNCE İPLİK SİPARİŞLERİ TABLOSUNU DÜZELT
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce iplik_siparisleri tablosunun yapısını kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'iplik_siparisleri' 
ORDER BY ordinal_position;

-- 2. Primary key var mı kontrol et
SELECT 
    tc.constraint_name, 
    tc.constraint_type, 
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'iplik_siparisleri';
