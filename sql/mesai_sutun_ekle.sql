-- Mesai tablosuna yemek_ucreti ve carpan sütunlarını ekle
-- Bu SQL'i Supabase SQL Editor'de çalıştırın

-- Yemek ücreti sütunu
ALTER TABLE public.mesai 
ADD COLUMN IF NOT EXISTS yemek_ucreti DECIMAL(10,2) DEFAULT 0;

-- Çarpan sütunu (mesai çarpanı: 1.5x, 2x, 3x vs)
ALTER TABLE public.mesai 
ADD COLUMN IF NOT EXISTS carpan DECIMAL(3,2) DEFAULT 1.0;

-- Kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'mesai' AND table_schema = 'public'
ORDER BY ordinal_position;
