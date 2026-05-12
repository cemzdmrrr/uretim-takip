-- Beden dagilimi verisinin kaybolmamasi icin eksik kolonlari ekler
-- Guvenli calisma: mevcutsa yeniden eklemez

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'konfeksiyon_atamalari'
  ) THEN
    ALTER TABLE public.konfeksiyon_atamalari
      ADD COLUMN IF NOT EXISTS beden_detaylari jsonb;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'sevkiyat_detaylari'
  ) THEN
    ALTER TABLE public.sevkiyat_detaylari
      ADD COLUMN IF NOT EXISTS beden_detaylari jsonb;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'konfeksiyon_atamalari'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_beden_detaylari
      ON public.konfeksiyon_atamalari USING gin (beden_detaylari);
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'sevkiyat_detaylari'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_beden_detaylari
      ON public.sevkiyat_detaylari USING gin (beden_detaylari);
  END IF;
END $$;
