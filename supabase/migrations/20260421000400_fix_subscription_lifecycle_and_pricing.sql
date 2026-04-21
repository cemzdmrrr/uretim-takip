ALTER TABLE public.abonelik_planlari
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.firma_abonelikleri
  DROP CONSTRAINT IF EXISTS chk_firma_abonelikleri_durum;

ALTER TABLE public.firma_abonelikleri
  ADD CONSTRAINT chk_firma_abonelikleri_durum
  CHECK (durum IN ('aktif', 'pasif', 'deneme', 'iptal', 'odeme_bekleniyor'));

ALTER TABLE public.firma_abonelikleri
  DROP CONSTRAINT IF EXISTS chk_firma_abonelikleri_odeme_periyodu;

ALTER TABLE public.firma_abonelikleri
  ADD CONSTRAINT chk_firma_abonelikleri_odeme_periyodu
  CHECK (odeme_periyodu IN ('aylik', 'yillik'));

WITH sirali AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY firma_id
      ORDER BY created_at DESC, id DESC
    ) AS sira
  FROM public.firma_abonelikleri
  WHERE durum IN ('aktif', 'deneme')
)
UPDATE public.firma_abonelikleri fa
SET
  durum = 'pasif',
  bitis_tarihi = COALESCE(fa.bitis_tarihi, now()),
  updated_at = now()
FROM sirali
WHERE fa.id = sirali.id
  AND sirali.sira > 1;

WITH sirali AS (
  SELECT
    id,
    row_number() OVER (
      PARTITION BY firma_id
      ORDER BY created_at DESC, id DESC
    ) AS sira
  FROM public.firma_abonelikleri
  WHERE durum = 'odeme_bekleniyor'
)
UPDATE public.firma_abonelikleri fa
SET
  durum = 'pasif',
  bitis_tarihi = COALESCE(fa.bitis_tarihi, now()),
  updated_at = now()
FROM sirali
WHERE fa.id = sirali.id
  AND sirali.sira > 1;

DROP INDEX IF EXISTS uniq_firma_aktif_abonelik;
CREATE UNIQUE INDEX uniq_firma_aktif_abonelik
  ON public.firma_abonelikleri (firma_id)
  WHERE durum IN ('aktif', 'deneme');

DROP INDEX IF EXISTS uniq_firma_bekleyen_abonelik;
CREATE UNIQUE INDEX uniq_firma_bekleyen_abonelik
  ON public.firma_abonelikleri (firma_id)
  WHERE durum = 'odeme_bekleniyor';

CREATE OR REPLACE FUNCTION public.abonelik_plan_fiyat_yonetebilir_mi()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.user_roles ur
    WHERE ur.user_id = v_user_id
      AND ur.role IN ('admin', 'platform_admin')
      AND COALESCE(ur.aktif, true) = true
  ) THEN
    RETURN true;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.firma_kullanicilari fk
    JOIN public.firmalar f ON f.id = fk.firma_id
    WHERE fk.user_id = v_user_id
      AND fk.rol IN ('firma_sahibi', 'firma_admin')
      AND COALESCE(fk.aktif, true) = true
      AND f.firma_kodu = 'varsayilan-firma'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.abonelik_plan_fiyat_guncelle(
  p_plan_id uuid,
  p_aylik_ucret numeric,
  p_yillik_ucret numeric DEFAULT NULL,
  p_aktif boolean DEFAULT true
)
RETURNS public.abonelik_planlari
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan public.abonelik_planlari;
BEGIN
  IF NOT public.abonelik_plan_fiyat_yonetebilir_mi() THEN
    RAISE EXCEPTION 'Abonelik plan fiyatlarini guncelleme yetkiniz yok';
  END IF;

  IF p_aylik_ucret IS NULL OR p_aylik_ucret < 0 THEN
    RAISE EXCEPTION 'Aylik ucret negatif olamaz';
  END IF;

  IF p_yillik_ucret IS NOT NULL AND p_yillik_ucret < 0 THEN
    RAISE EXCEPTION 'Yillik ucret negatif olamaz';
  END IF;

  UPDATE public.abonelik_planlari
  SET
    aylik_ucret = p_aylik_ucret,
    yillik_ucret = p_yillik_ucret,
    aktif = COALESCE(p_aktif, aktif),
    updated_at = now()
  WHERE id = p_plan_id
  RETURNING * INTO v_plan;

  IF v_plan.id IS NULL THEN
    RAISE EXCEPTION 'Plan bulunamadi';
  END IF;

  RETURN v_plan;
END;
$$;

GRANT EXECUTE ON FUNCTION public.abonelik_plan_fiyat_yonetebilir_mi() TO authenticated;
GRANT EXECUTE ON FUNCTION public.abonelik_plan_fiyat_guncelle(uuid, numeric, numeric, boolean) TO authenticated;
