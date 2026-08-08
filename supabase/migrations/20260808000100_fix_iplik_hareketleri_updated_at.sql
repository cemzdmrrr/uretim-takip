-- Lokasyonlu teslimat, transfer ve sayim RPC'leri hareket kaydini
-- guncellerken bu alani kullanir. Eski canli semalarda kolon eksik kalabilir.
ALTER TABLE public.iplik_hareketleri
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

UPDATE public.iplik_hareketleri
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE public.iplik_hareketleri
ALTER COLUMN updated_at SET DEFAULT now();
