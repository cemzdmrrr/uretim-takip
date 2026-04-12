-- HIZLI DÜZELTİCİ: Eksik kolonları ekle ve sorunları çöz

-- 1. odeme_kayitlari tablosuna eksik kolonları ekle
ALTER TABLE public.odeme_kayitlari 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID; -- Flutter'ın aradığı kolon adı

-- 2. izinler tablosuna eksik kolonları ekle  
ALTER TABLE public.izinler 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID; -- Flutter'ın aradığı kolon adı

-- 3. mesai tablosuna eksik kolonları ekle
ALTER TABLE public.mesai 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID; -- Flutter'ın aradığı kolon adı

-- 4. personel_arsiv tablosuna eksik kolonları ekle
ALTER TABLE public.personel_arsiv 
ADD COLUMN IF NOT EXISTS onaylayan_id UUID; -- Flutter'ın aradığı kolon adı

-- 5. Mevcut onaylayan_user_id verilerini onaylayan_id'ye kopyala
UPDATE public.odeme_kayitlari 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

UPDATE public.izinler 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

UPDATE public.mesai 
SET onaylayan_id = onaylayan_user_id 
WHERE onaylayan_user_id IS NOT NULL AND onaylayan_id IS NULL;

UPDATE public.personel_arsiv 
SET onaylayan_id = yukleyen_user_id 
WHERE yukleyen_user_id IS NOT NULL AND onaylayan_id IS NULL;

-- 6. Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_onaylayan_id ON public.odeme_kayitlari(onaylayan_id);
CREATE INDEX IF NOT EXISTS idx_izinler_onaylayan_id ON public.izinler(onaylayan_id);
CREATE INDEX IF NOT EXISTS idx_mesai_onaylayan_id ON public.mesai(onaylayan_id);
CREATE INDEX IF NOT EXISTS idx_personel_arsiv_onaylayan_id ON public.personel_arsiv(onaylayan_id);

-- 7. Kontrol sorguları
SELECT 'odeme_kayitlari' as tablo, 
       COUNT(*) as toplam, 
       COUNT(CASE WHEN onaylayan_id IS NOT NULL THEN 1 END) as onaylayan_id_dolu,
       COUNT(CASE WHEN onaylayan_user_id IS NOT NULL THEN 1 END) as onaylayan_user_id_dolu
FROM public.odeme_kayitlari
UNION ALL
SELECT 'izinler' as tablo, 
       COUNT(*) as toplam, 
       COUNT(CASE WHEN onaylayan_id IS NOT NULL THEN 1 END) as onaylayan_id_dolu,
       COUNT(CASE WHEN onaylayan_user_id IS NOT NULL THEN 1 END) as onaylayan_user_id_dolu
FROM public.izinler
UNION ALL
SELECT 'mesai' as tablo, 
       COUNT(*) as toplam, 
       COUNT(CASE WHEN onaylayan_id IS NOT NULL THEN 1 END) as onaylayan_id_dolu,
       COUNT(CASE WHEN onaylayan_user_id IS NOT NULL THEN 1 END) as onaylayan_user_id_dolu
FROM public.mesai
UNION ALL
SELECT 'personel_arsiv' as tablo, 
       COUNT(*) as toplam, 
       COUNT(CASE WHEN onaylayan_id IS NOT NULL THEN 1 END) as onaylayan_id_dolu,
       COUNT(CASE WHEN yukleyen_user_id IS NOT NULL THEN 1 END) as yukleyen_user_id_dolu
FROM public.personel_arsiv;

RAISE NOTICE 'Tüm eksik kolonlar eklendi ve veriler kopyalandı!';
