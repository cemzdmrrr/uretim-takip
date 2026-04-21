-- Existing seeded/default firm was created before production branch assignments.
-- Keep the default tenant usable on the General Production page.

INSERT INTO public.firma_uretim_modulleri (
  firma_id,
  uretim_modul_id,
  tekstil_dali,
  aktif,
  aktivasyon_tarihi,
  bitis_tarihi,
  updated_at
)
SELECT
  f.id,
  um.id,
  COALESCE(um.tekstil_dali, um.modul_kodu),
  true,
  now(),
  null,
  now()
FROM public.firmalar f
JOIN public.uretim_modulleri um
  ON um.modul_kodu = 'triko'
WHERE f.firma_kodu = 'varsayilan-firma'
ON CONFLICT (firma_id, uretim_modul_id)
DO UPDATE SET
  aktif = true,
  tekstil_dali = COALESCE(EXCLUDED.tekstil_dali, public.firma_uretim_modulleri.tekstil_dali),
  aktivasyon_tarihi = COALESCE(public.firma_uretim_modulleri.aktivasyon_tarihi, now()),
  bitis_tarihi = null,
  updated_at = now();
