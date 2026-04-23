ALTER TABLE public.personel
ADD COLUMN IF NOT EXISTS isten_cikis_tarihi DATE,
ADD COLUMN IF NOT EXISTS isten_cikis_nedeni TEXT,
ADD COLUMN IF NOT EXISTS silme_tarihi TIMESTAMP WITH TIME ZONE;

UPDATE public.personel
SET durum = 'aktif'
WHERE durum IS NULL OR btrim(durum) = '';
