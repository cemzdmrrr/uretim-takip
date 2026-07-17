-- Repair environments where actionable notification columns were not applied.

ALTER TABLE public.bildirimler
  ADD COLUMN IF NOT EXISTS ek_bilgi jsonb;

ALTER TABLE public.bildirimler
  ADD COLUMN IF NOT EXISTS event_key text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_bildirimler_event_key_unique
  ON public.bildirimler (firma_id, user_id, event_key)
  WHERE event_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bildirimler_firma_user_created
  ON public.bildirimler (firma_id, user_id, created_at DESC);
