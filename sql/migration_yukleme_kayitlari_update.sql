-- Migration: Yukleme kayitlari tablosuna kaynak ve ceki_id kolonları ekle
-- Bu migration çalıştırılmalı Supabase'de

-- Eğer tablo mevcutsa ve kolonlar yoksa ekle
ALTER TABLE IF EXISTS public.yukleme_kayitlari
ADD COLUMN IF NOT EXISTS kaynak VARCHAR(50) DEFAULT 'manual';

ALTER TABLE IF EXISTS public.yukleme_kayitlari
ADD COLUMN IF NOT EXISTS ceki_id UUID;

-- Indeks ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_yukleme_kayitlari_kaynak ON public.yukleme_kayitlari(kaynak);
CREATE INDEX IF NOT EXISTS idx_yukleme_kayitlari_ceki_id ON public.yukleme_kayitlari(ceki_id);

-- UUID tablo için alternatif (eğer tabloda UUID tipinde id varsa)
-- ALTER TABLE IF EXISTS yukleme_kayitlari
-- ADD COLUMN IF NOT EXISTS kaynak VARCHAR(50) DEFAULT 'manual';
-- 
-- ALTER TABLE IF EXISTS yukleme_kayitlari
-- ADD COLUMN IF NOT EXISTS ceki_id UUID;

COMMENT ON COLUMN public.yukleme_kayitlari.kaynak IS 'Yükleme kaynağı: manual (manuel giriş) veya ceki_listesi (çeki listesinden otomatik)';
COMMENT ON COLUMN public.yukleme_kayitlari.ceki_id IS 'Çeki listesi id (kaynak ceki_listesi ise)';
