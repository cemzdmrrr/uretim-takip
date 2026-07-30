-- Iplik ozelliklerini ayristirir ve stok/siparis bazli model rezervasyonlarini ekler.

ALTER TABLE public.iplik_stoklari
  ADD COLUMN IF NOT EXISTS iplik_kalinligi text,
  ADD COLUMN IF NOT EXISTS iplik_karisimi text,
  ADD COLUMN IF NOT EXISTS renk_kodu text;

ALTER TABLE public.iplik_siparisleri
  ADD COLUMN IF NOT EXISTS iplik_kalinligi text,
  ADD COLUMN IF NOT EXISTS iplik_karisimi text,
  ADD COLUMN IF NOT EXISTS renk_kodu text,
  ADD COLUMN IF NOT EXISTS lot_no text;

-- Bazi mevcut kurulumlarda eski iplik depo transaction migration'i
-- uygulanmadigi icin teslimat tablosu bulunmayabilir.
CREATE TABLE IF NOT EXISTS public.iplik_siparis_teslimatlar (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  siparis_id uuid NOT NULL
    REFERENCES public.iplik_siparisleri(id) ON DELETE CASCADE,
  firma_id uuid,
  teslim_kg numeric(10,2) NOT NULL CHECK (teslim_kg > 0),
  iplik_lotu text,
  gelis_tarihi date NOT NULL DEFAULT CURRENT_DATE,
  teslimat_durumu text NOT NULL DEFAULT 'kismi_teslimat',
  kalite_durumu text DEFAULT 'onaylandi',
  aciklama text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_firma_id
  ON public.iplik_siparis_teslimatlar(firma_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_siparis_id
  ON public.iplik_siparis_teslimatlar(siparis_id);

CREATE TABLE IF NOT EXISTS public.iplik_stok_model_tahsisleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL,
  stok_id uuid NOT NULL REFERENCES public.iplik_stoklari(id) ON DELETE CASCADE,
  model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
  tahsis_miktari numeric(12,2) NOT NULL CHECK (tahsis_miktari > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (firma_id, stok_id, model_id)
);

CREATE TABLE IF NOT EXISTS public.iplik_siparis_model_tahsisleri (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id uuid NOT NULL,
  siparis_id uuid NOT NULL REFERENCES public.iplik_siparisleri(id) ON DELETE CASCADE,
  model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
  tahsis_miktari numeric(12,2) NOT NULL CHECK (tahsis_miktari > 0),
  aktarilan_miktar numeric(12,2) NOT NULL DEFAULT 0 CHECK (aktarilan_miktar >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (firma_id, siparis_id, model_id)
);

CREATE INDEX IF NOT EXISTS idx_iplik_stok_model_tahsis_firma_stok
  ON public.iplik_stok_model_tahsisleri(firma_id, stok_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_model_tahsis_firma_siparis
  ON public.iplik_siparis_model_tahsisleri(firma_id, siparis_id);

ALTER TABLE public.iplik_stok_model_tahsisleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_siparis_model_tahsisleri ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS iplik_stok_model_tahsis_firma ON public.iplik_stok_model_tahsisleri;
CREATE POLICY iplik_stok_model_tahsis_firma ON public.iplik_stok_model_tahsisleri
  FOR ALL USING (exists (
    select 1 from public.firma_kullanicilari fk
    where fk.firma_id = iplik_stok_model_tahsisleri.firma_id
      and fk.user_id = auth.uid() and fk.aktif = true
  )) WITH CHECK (exists (
    select 1 from public.firma_kullanicilari fk
    where fk.firma_id = iplik_stok_model_tahsisleri.firma_id
      and fk.user_id = auth.uid() and fk.aktif = true
  ));
DROP POLICY IF EXISTS iplik_siparis_model_tahsis_firma ON public.iplik_siparis_model_tahsisleri;
CREATE POLICY iplik_siparis_model_tahsis_firma ON public.iplik_siparis_model_tahsisleri
  FOR ALL USING (exists (
    select 1 from public.firma_kullanicilari fk
    where fk.firma_id = iplik_siparis_model_tahsisleri.firma_id
      and fk.user_id = auth.uid() and fk.aktif = true
  )) WITH CHECK (exists (
    select 1 from public.firma_kullanicilari fk
    where fk.firma_id = iplik_siparis_model_tahsisleri.firma_id
      and fk.user_id = auth.uid() and fk.aktif = true
  ));

CREATE OR REPLACE FUNCTION public.iplik_model_tahsisleri_kaydet(
  p_firma_id uuid,
  p_kaynak_tipi text,
  p_kaynak_id uuid,
  p_tahsisler jsonb
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_limit numeric;
  v_toplam numeric;
  v_item jsonb;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.firma_kullanicilari fk
    WHERE fk.firma_id = p_firma_id AND fk.user_id = auth.uid()
      AND fk.aktif = true
  ) THEN
    RAISE EXCEPTION 'Firma erisim yetkisi yok';
  END IF;
  IF p_kaynak_tipi NOT IN ('stok', 'siparis') THEN
    RAISE EXCEPTION 'Gecersiz tahsis kaynak tipi';
  END IF;

  SELECT coalesce(sum((x->>'tahsis_miktari')::numeric), 0)
    INTO v_toplam FROM jsonb_array_elements(coalesce(p_tahsisler, '[]')) x;
  IF v_toplam < 0 THEN RAISE EXCEPTION 'Tahsis miktari negatif olamaz'; END IF;

  IF p_kaynak_tipi = 'stok' THEN
    SELECT miktar INTO v_limit FROM public.iplik_stoklari
      WHERE id = p_kaynak_id AND firma_id = p_firma_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Iplik stogu bulunamadi'; END IF;
    IF v_toplam > coalesce(v_limit, 0) THEN
      RAISE EXCEPTION 'Toplam tahsis stok miktarini asamaz';
    END IF;
    DELETE FROM public.iplik_stok_model_tahsisleri
      WHERE firma_id = p_firma_id AND stok_id = p_kaynak_id;
    FOR v_item IN SELECT * FROM jsonb_array_elements(coalesce(p_tahsisler, '[]')) LOOP
      IF (v_item->>'tahsis_miktari')::numeric > 0 THEN
        INSERT INTO public.iplik_stok_model_tahsisleri
          (firma_id, stok_id, model_id, tahsis_miktari)
        VALUES (p_firma_id, p_kaynak_id, (v_item->>'model_id')::uuid,
                (v_item->>'tahsis_miktari')::numeric);
      END IF;
    END LOOP;
  ELSE
    SELECT miktar INTO v_limit FROM public.iplik_siparisleri
      WHERE id = p_kaynak_id AND firma_id = p_firma_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Iplik siparisi bulunamadi'; END IF;
    IF v_toplam > coalesce(v_limit, 0) THEN
      RAISE EXCEPTION 'Toplam tahsis siparis miktarini asamaz';
    END IF;
    DELETE FROM public.iplik_siparis_model_tahsisleri
      WHERE firma_id = p_firma_id AND siparis_id = p_kaynak_id;
    FOR v_item IN SELECT * FROM jsonb_array_elements(coalesce(p_tahsisler, '[]')) LOOP
      IF (v_item->>'tahsis_miktari')::numeric > 0 THEN
        INSERT INTO public.iplik_siparis_model_tahsisleri
          (firma_id, siparis_id, model_id, tahsis_miktari)
        VALUES (p_firma_id, p_kaynak_id, (v_item->>'model_id')::uuid,
                (v_item->>'tahsis_miktari')::numeric);
      END IF;
    END LOOP;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.iplik_model_tahsisleri_kaydet(uuid,text,uuid,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.iplik_model_tahsisleri_kaydet(uuid,text,uuid,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.iplik_rezervasyonlu_stok_hareket_kaydet(
  p_firma_id uuid,
  p_iplik_id uuid DEFAULT NULL,
  p_stok_data jsonb DEFAULT NULL,
  p_hareket_tipi text DEFAULT 'giris',
  p_miktar numeric DEFAULT 0,
  p_aciklama text DEFAULT NULL,
  p_model_id uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_rezerve numeric := 0;
  v_model_rezerve numeric := 0;
  v_stok numeric := 0;
  v_sonuc jsonb;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.firma_kullanicilari fk
    WHERE fk.firma_id = p_firma_id AND fk.user_id = auth.uid()
      AND fk.aktif = true
  ) THEN
    RAISE EXCEPTION 'Firma erisim yetkisi yok';
  END IF;
  IF p_iplik_id IS NOT NULL AND p_hareket_tipi IN ('cikis', 'transfer') THEN
    SELECT miktar INTO v_stok FROM public.iplik_stoklari
      WHERE id = p_iplik_id AND firma_id = p_firma_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Iplik stogu bulunamadi'; END IF;
    SELECT coalesce(sum(tahsis_miktari), 0) INTO v_rezerve
      FROM public.iplik_stok_model_tahsisleri
      WHERE firma_id = p_firma_id AND stok_id = p_iplik_id;
    IF p_model_id IS NULL THEN
      IF p_miktar > v_stok - v_rezerve THEN
        RAISE EXCEPTION 'Modelsiz cikis rezerve edilmemis stogu asamaz';
      END IF;
    ELSE
      SELECT coalesce(tahsis_miktari, 0) INTO v_model_rezerve
        FROM public.iplik_stok_model_tahsisleri
        WHERE firma_id = p_firma_id AND stok_id = p_iplik_id
          AND model_id = p_model_id FOR UPDATE;
      IF p_miktar > v_model_rezerve THEN
        RAISE EXCEPTION 'Model icin ayrilan miktar yetersiz';
      END IF;
    END IF;
  END IF;

  v_sonuc := public.iplik_stok_hareket_kaydet(
    p_firma_id, p_iplik_id, p_stok_data, p_hareket_tipi,
    p_miktar, p_aciklama, p_model_id
  );

  IF p_iplik_id IS NOT NULL AND p_model_id IS NOT NULL
     AND p_hareket_tipi IN ('cikis', 'transfer') THEN
    UPDATE public.iplik_stok_model_tahsisleri
      SET tahsis_miktari = tahsis_miktari - p_miktar, updated_at = now()
      WHERE firma_id = p_firma_id AND stok_id = p_iplik_id
        AND model_id = p_model_id;
    DELETE FROM public.iplik_stok_model_tahsisleri
      WHERE firma_id = p_firma_id AND stok_id = p_iplik_id
        AND model_id = p_model_id AND tahsis_miktari <= 0;
  END IF;
  RETURN v_sonuc;
END;
$$;

REVOKE ALL ON FUNCTION public.iplik_rezervasyonlu_stok_hareket_kaydet(uuid,uuid,jsonb,text,numeric,text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.iplik_rezervasyonlu_stok_hareket_kaydet(uuid,uuid,jsonb,text,numeric,text,uuid) TO authenticated;

DROP VIEW IF EXISTS public.v_siparis_takip CASCADE;
CREATE VIEW public.v_siparis_takip AS
SELECT
  s.*,
  t.sirket AS tedarikci_adi,
  t.telefon AS tedarikci_telefon,
  o.sirket AS orgu_firmasi_adi,
  o.telefon AS orgu_firmasi_telefon,
  CASE
    WHEN s.teslim_edildi = true THEN 'tamamlandi'
    WHEN s.termin_tarihi IS NOT NULL AND s.termin_tarihi < CURRENT_DATE
      AND s.teslim_edildi != true THEN 'gecikti'
    ELSE 'beklemede'
  END AS takip_durumu
FROM public.iplik_siparisleri s
LEFT JOIN public.tedarikciler t
  ON s.tedarikci_id = t.id AND s.firma_id = t.firma_id
LEFT JOIN public.tedarikciler o
  ON s.orgu_firmasi_id = o.id AND s.firma_id = o.firma_id;

CREATE OR REPLACE FUNCTION public.iplik_teslimat_ozellik_tahsis_aktar()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_siparis public.iplik_siparisleri%ROWTYPE;
  v_stok_id uuid;
  v_tahsis record;
  v_aktar numeric;
BEGIN
  SELECT * INTO v_siparis FROM public.iplik_siparisleri
    WHERE id = NEW.siparis_id AND firma_id = NEW.firma_id;
  IF NOT FOUND THEN RETURN NEW; END IF;

  SELECT id INTO v_stok_id FROM public.iplik_stoklari
    WHERE firma_id = NEW.firma_id
      AND ad = v_siparis.iplik_adi
      AND coalesce(renk, '') = coalesce(v_siparis.renk, '')
      AND coalesce(lot_no, '') = coalesce(NEW.iplik_lotu, '')
      AND coalesce(tedarikci_id::text, '') = coalesce(v_siparis.tedarikci_id::text, '')
    ORDER BY created_at DESC LIMIT 1;
  IF v_stok_id IS NULL THEN RETURN NEW; END IF;

  UPDATE public.iplik_stoklari SET
    iplik_kalinligi = v_siparis.iplik_kalinligi,
    iplik_karisimi = v_siparis.iplik_karisimi,
    renk_kodu = v_siparis.renk_kodu,
    updated_at = now()
  WHERE id = v_stok_id AND firma_id = NEW.firma_id;

  FOR v_tahsis IN
    SELECT * FROM public.iplik_siparis_model_tahsisleri
      WHERE firma_id = NEW.firma_id AND siparis_id = NEW.siparis_id
      FOR UPDATE
  LOOP
    v_aktar := CASE
      WHEN coalesce(v_siparis.miktar, 0) <= 0 THEN 0
      WHEN v_siparis.teslim_edildi THEN
        greatest(v_tahsis.tahsis_miktari - v_tahsis.aktarilan_miktar, 0)
      ELSE least(
        round(v_tahsis.tahsis_miktari * NEW.teslim_kg / v_siparis.miktar, 2),
        greatest(v_tahsis.tahsis_miktari - v_tahsis.aktarilan_miktar, 0)
      )
    END;
    IF v_aktar > 0 THEN
      INSERT INTO public.iplik_stok_model_tahsisleri
        (firma_id, stok_id, model_id, tahsis_miktari)
      VALUES (NEW.firma_id, v_stok_id, v_tahsis.model_id, v_aktar)
      ON CONFLICT (firma_id, stok_id, model_id) DO UPDATE
        SET tahsis_miktari = public.iplik_stok_model_tahsisleri.tahsis_miktari
            + EXCLUDED.tahsis_miktari,
            updated_at = now();
      UPDATE public.iplik_siparis_model_tahsisleri
        SET aktarilan_miktar = aktarilan_miktar + v_aktar, updated_at = now()
        WHERE id = v_tahsis.id;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_iplik_teslimat_ozellik_tahsis
  ON public.iplik_siparis_teslimatlar;
CREATE TRIGGER trg_iplik_teslimat_ozellik_tahsis
AFTER INSERT ON public.iplik_siparis_teslimatlar
FOR EACH ROW EXECUTE FUNCTION public.iplik_teslimat_ozellik_tahsis_aktar();
