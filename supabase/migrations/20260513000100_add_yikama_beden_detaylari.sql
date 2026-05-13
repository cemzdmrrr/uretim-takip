-- Yikama atamalarinda sevkiyattan gelen beden dagilimini kalici sakla.
-- Konfeksiyon paneli ile ayni beden bazli akisi destekler.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'yikama_atamalari'
  ) THEN
    ALTER TABLE public.yikama_atamalari
      ADD COLUMN IF NOT EXISTS beden_detaylari jsonb;

    CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_beden_detaylari
      ON public.yikama_atamalari USING gin (beden_detaylari);
  END IF;
END $$;
