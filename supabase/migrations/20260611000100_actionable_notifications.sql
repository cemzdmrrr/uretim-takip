-- Actionable, tenant-scoped notifications.
-- Run after the existing bildirimler table migration.

ALTER TABLE public.bildirimler
  ADD COLUMN IF NOT EXISTS ek_bilgi jsonb;

ALTER TABLE public.bildirimler
  ADD COLUMN IF NOT EXISTS event_key text;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'bildirimler'
      AND constraint_name = 'bildirimler_tip_check'
  ) THEN
    ALTER TABLE public.bildirimler DROP CONSTRAINT bildirimler_tip_check;
  END IF;
END $$;

ALTER TABLE public.bildirimler
  ADD CONSTRAINT bildirimler_tip_check
  CHECK (
    tip = ANY (
      ARRAY[
        'atama_bekliyor'::text,
        'atama_onaylandi'::text,
        'atama_reddedildi'::text,
        'uretim_tamamlandi'::text,
        'kalite_onay'::text,
        'kalite_red'::text,
        'sevkiyat_hazir'::text,
        'stok_uyari'::text,
        'termin_uyari'::text,
        'siparis_yeni'::text,
        'mesai_talebi'::text,
        'avans_talebi'::text,
        'izin_talebi'::text,
        'genel'::text
      ]
    )
  );

CREATE UNIQUE INDEX IF NOT EXISTS idx_bildirimler_event_key_unique
  ON public.bildirimler (firma_id, user_id, event_key)
  WHERE event_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bildirimler_firma_user_created
  ON public.bildirimler (firma_id, user_id, created_at DESC);
