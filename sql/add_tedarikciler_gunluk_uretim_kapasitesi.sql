-- Tedarikci bazli gunluk uretim kapasitesi alani
-- Guvenli calisma: kolon varsa yeniden eklemez

ALTER TABLE IF EXISTS public.tedarikciler
  ADD COLUMN IF NOT EXISTS gunluk_uretim_kapasitesi numeric(12,2);

COMMENT ON COLUMN public.tedarikciler.gunluk_uretim_kapasitesi
  IS 'Tedarikcinin gunluk uretim kapasitesi (adet/gun)';
