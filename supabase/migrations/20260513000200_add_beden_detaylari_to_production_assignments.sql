-- Tum uretim atama tablolarinda beden dagilimini kalici sakla.
-- Konfeksiyon panelindeki beden bazli akisi diger asamalar icin de destekler.

DO $$
DECLARE
  tablo text;
  tablolar text[] := ARRAY[
    'dokuma_atamalari',
    'nakis_atamalari',
    'konfeksiyon_atamalari',
    'yikama_atamalari',
    'utu_atamalari',
    'ilik_dugme_atamalari',
    'kalite_kontrol_atamalari',
    'paketleme_atamalari'
  ];
BEGIN
  FOREACH tablo IN ARRAY tablolar LOOP
    IF EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = tablo
    ) THEN
      EXECUTE format(
        'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS beden_detaylari jsonb',
        tablo
      );

      EXECUTE format(
        'CREATE INDEX IF NOT EXISTS %I ON public.%I USING gin (beden_detaylari)',
        'idx_' || tablo || '_beden_detaylari',
        tablo
      );
    END IF;
  END LOOP;
END $$;
