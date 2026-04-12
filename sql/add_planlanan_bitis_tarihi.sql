-- Tüm atama tablolarına planlanan_bitis_tarihi sütunu ekle
-- Bu sütun üretime alırken seçilen bitiş tarihini tutar

-- Dokuma atamaları
ALTER TABLE public.dokuma_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Konfeksiyon atamaları
ALTER TABLE public.konfeksiyon_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Yıkama atamaları
ALTER TABLE public.yikama_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Ütü atamaları
ALTER TABLE public.utu_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- İlik düğme atamaları
ALTER TABLE public.ilik_dugme_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Paketleme atamaları
ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Kalite kontrol atamaları
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE;

-- Kalite kontrol atamaları - kontrol_edilecek_adet sütunu ekle
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS kontrol_edilecek_adet INTEGER;

-- Yorum: Bu SQL'i Supabase SQL Editor'de çalıştırın
