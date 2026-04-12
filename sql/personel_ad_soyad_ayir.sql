-- Personel tablosunda ad_soyad alanını ad ve soyad olarak ayır
-- Bu script veritabanında ad_soyad tek alanı varsa çalıştırılmalı

-- Önce yeni sütunları ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS ad VARCHAR(100),
ADD COLUMN IF NOT EXISTS soyad VARCHAR(100);

-- Mevcut ad_soyad verilerini böl (boşluk ile ayrılanları)
UPDATE public.personel 
SET 
    ad = CASE 
        WHEN ad_soyad IS NOT NULL AND position(' ' in ad_soyad) > 0 
        THEN split_part(ad_soyad, ' ', 1)
        ELSE ad_soyad
    END,
    soyad = CASE 
        WHEN ad_soyad IS NOT NULL AND position(' ' in ad_soyad) > 0 
        THEN trim(substring(ad_soyad from position(' ' in ad_soyad) + 1))
        ELSE ''
    END
WHERE ad_soyad IS NOT NULL;

-- ad alanını NOT NULL yap
ALTER TABLE public.personel 
ALTER COLUMN ad SET NOT NULL;

-- Eski ad_soyad sütununu kaldır (isteğe bağlı)
-- ALTER TABLE public.personel DROP COLUMN IF EXISTS ad_soyad;

-- Kontrol sorgusu
SELECT user_id, ad, soyad, ad_soyad FROM public.personel LIMIT 10;
