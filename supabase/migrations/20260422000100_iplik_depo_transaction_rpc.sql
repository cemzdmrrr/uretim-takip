-- Iplik depo islemlerini tek transaction icinde yurutmek icin RPC fonksiyonlari.

ALTER TABLE public.iplik_stoklari ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.iplik_hareketleri ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS teslim_miktari numeric DEFAULT 0;
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS teslim_yuzdesi numeric DEFAULT 0;
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS kalite_durumu text DEFAULT 'onaylandi';
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS teslim_edildi boolean DEFAULT false;
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS teslim_tarihi date;
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS kapanma_tarihi date;
ALTER TABLE public.iplik_siparisleri ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

CREATE TABLE IF NOT EXISTS public.iplik_siparis_teslimatlar (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  siparis_id uuid NOT NULL REFERENCES public.iplik_siparisleri(id) ON DELETE CASCADE,
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

ALTER TABLE public.iplik_siparis_teslimatlar ADD COLUMN IF NOT EXISTS firma_id uuid;
ALTER TABLE public.iplik_siparis_teslimatlar ADD COLUMN IF NOT EXISTS kalite_durumu text DEFAULT 'onaylandi';
ALTER TABLE public.iplik_siparis_teslimatlar ADD COLUMN IF NOT EXISTS aciklama text;

CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_firma_id
  ON public.iplik_siparis_teslimatlar(firma_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_siparis_id
  ON public.iplik_siparis_teslimatlar(siparis_id);

CREATE OR REPLACE FUNCTION public.iplik_stok_hareket_kaydet(
  p_firma_id uuid,
  p_iplik_id uuid DEFAULT NULL,
  p_stok_data jsonb DEFAULT NULL,
  p_hareket_tipi text DEFAULT 'giris',
  p_miktar numeric DEFAULT 0,
  p_aciklama text DEFAULT NULL,
  p_model_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_iplik_id uuid;
  v_mevcut_miktar numeric;
  v_yeni_miktar numeric;
  v_birim_fiyat numeric;
BEGIN
  IF p_firma_id IS NULL THEN
    RAISE EXCEPTION 'Firma bilgisi zorunludur';
  END IF;

  IF p_miktar IS NULL OR p_miktar < 0 THEN
    RAISE EXCEPTION 'Gecerli bir miktar girin';
  END IF;

  IF p_hareket_tipi NOT IN ('giris', 'cikis', 'transfer', 'sayim') THEN
    RAISE EXCEPTION 'Gecersiz hareket tipi: %', p_hareket_tipi;
  END IF;

  IF p_iplik_id IS NULL THEN
    IF p_stok_data IS NULL OR coalesce(p_stok_data->>'ad', '') = '' THEN
      RAISE EXCEPTION 'Yeni stok icin iplik adi zorunludur';
    END IF;

    INSERT INTO public.iplik_stoklari (
      ad,
      renk,
      lot_no,
      miktar,
      birim,
      birim_fiyat,
      para_birimi,
      toplam_deger,
      tedarikci_id,
      firma_id,
      created_at,
      updated_at
    )
    VALUES (
      p_stok_data->>'ad',
      NULLIF(p_stok_data->>'renk', ''),
      NULLIF(p_stok_data->>'lot_no', ''),
      p_miktar,
      coalesce(NULLIF(p_stok_data->>'birim', ''), 'kg'),
      NULLIF(p_stok_data->>'birim_fiyat', '')::numeric,
      coalesce(NULLIF(p_stok_data->>'para_birimi', ''), 'TL'),
      CASE
        WHEN NULLIF(p_stok_data->>'birim_fiyat', '') IS NULL THEN NULL
        ELSE p_miktar * NULLIF(p_stok_data->>'birim_fiyat', '')::numeric
      END,
      NULLIF(p_stok_data->>'tedarikci_id', '')::uuid,
      p_firma_id,
      now(),
      now()
    )
    RETURNING id INTO v_iplik_id;

    v_yeni_miktar := p_miktar;
  ELSE
    SELECT id, miktar, birim_fiyat
    INTO v_iplik_id, v_mevcut_miktar, v_birim_fiyat
    FROM public.iplik_stoklari
    WHERE id = p_iplik_id
      AND firma_id = p_firma_id
    FOR UPDATE;

    IF v_iplik_id IS NULL THEN
      RAISE EXCEPTION 'Iplik stogu bulunamadi';
    END IF;

    IF p_hareket_tipi = 'giris' THEN
      v_yeni_miktar := v_mevcut_miktar + p_miktar;
    ELSIF p_hareket_tipi IN ('cikis', 'transfer') THEN
      IF p_miktar > v_mevcut_miktar THEN
        RAISE EXCEPTION 'Yetersiz stok miktari. Mevcut: % kg', v_mevcut_miktar;
      END IF;
      v_yeni_miktar := v_mevcut_miktar - p_miktar;
    ELSE
      v_yeni_miktar := p_miktar;
    END IF;

    UPDATE public.iplik_stoklari
    SET
      miktar = v_yeni_miktar,
      toplam_deger = CASE
        WHEN v_birim_fiyat IS NULL THEN NULL
        ELSE v_yeni_miktar * v_birim_fiyat
      END,
      updated_at = now()
    WHERE id = v_iplik_id
      AND firma_id = p_firma_id;
  END IF;

  INSERT INTO public.iplik_hareketleri (
    iplik_id,
    hareket_tipi,
    miktar,
    aciklama,
    model_id,
    firma_id,
    created_at,
    updated_at
  )
  VALUES (
    v_iplik_id,
    p_hareket_tipi,
    p_miktar,
    p_aciklama,
    p_model_id,
    p_firma_id,
    now(),
    now()
  );

  RETURN jsonb_build_object(
    'iplik_id', v_iplik_id,
    'yeni_miktar', v_yeni_miktar
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.iplik_siparis_teslimat_kaydet(
  p_firma_id uuid,
  p_siparis_id uuid,
  p_miktar numeric,
  p_lot_no text DEFAULT NULL,
  p_kalite_durumu text DEFAULT 'onaylandi',
  p_teslimat_tarihi date DEFAULT CURRENT_DATE,
  p_aciklama text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_siparis public.iplik_siparisleri%ROWTYPE;
  v_toplam_teslim numeric;
  v_teslim_yuzdesi numeric;
  v_teslim_edildi boolean;
  v_stok_id uuid;
  v_stok_miktar numeric;
BEGIN
  IF p_firma_id IS NULL THEN
    RAISE EXCEPTION 'Firma bilgisi zorunludur';
  END IF;

  IF p_miktar IS NULL OR p_miktar <= 0 THEN
    RAISE EXCEPTION 'Gecerli bir teslim miktari girin';
  END IF;

  SELECT *
  INTO v_siparis
  FROM public.iplik_siparisleri
  WHERE id = p_siparis_id
    AND firma_id = p_firma_id
  FOR UPDATE;

  IF v_siparis.id IS NULL THEN
    RAISE EXCEPTION 'Iplik siparisi bulunamadi';
  END IF;

  IF p_miktar > (coalesce(v_siparis.miktar, 0) - coalesce(v_siparis.teslim_miktari, 0)) THEN
    RAISE EXCEPTION 'Teslim miktari kalan miktardan fazla olamaz';
  END IF;

  v_toplam_teslim := coalesce(v_siparis.teslim_miktari, 0) + p_miktar;
  v_teslim_yuzdesi := CASE
    WHEN coalesce(v_siparis.miktar, 0) <= 0 THEN 0
    ELSE (v_toplam_teslim / v_siparis.miktar) * 100
  END;
  v_teslim_edildi := v_toplam_teslim >= coalesce(v_siparis.miktar, 0);

  UPDATE public.iplik_siparisleri
  SET
    teslim_miktari = v_toplam_teslim,
    teslim_yuzdesi = v_teslim_yuzdesi,
    teslim_tarihi = p_teslimat_tarihi,
    teslim_edildi = v_teslim_edildi,
    lot_no = NULLIF(p_lot_no, ''),
    kalite_durumu = p_kalite_durumu,
    durum = CASE WHEN v_teslim_edildi THEN 'teslim_edildi' ELSE coalesce(durum, 'beklemede') END,
    updated_at = now()
  WHERE id = p_siparis_id
    AND firma_id = p_firma_id;

  SELECT id, miktar
  INTO v_stok_id, v_stok_miktar
  FROM public.iplik_stoklari
  WHERE firma_id = p_firma_id
    AND ad = v_siparis.iplik_adi
    AND coalesce(renk, '') = coalesce(v_siparis.renk, '')
    AND coalesce(lot_no, '') = coalesce(NULLIF(p_lot_no, ''), '')
    AND coalesce(tedarikci_id::text, '') = coalesce(v_siparis.tedarikci_id::text, '')
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_stok_id IS NULL THEN
    INSERT INTO public.iplik_stoklari (
      ad,
      renk,
      lot_no,
      miktar,
      birim,
      birim_fiyat,
      para_birimi,
      toplam_deger,
      tedarikci_id,
      firma_id,
      created_at,
      updated_at
    )
    VALUES (
      v_siparis.iplik_adi,
      v_siparis.renk,
      NULLIF(p_lot_no, ''),
      p_miktar,
      coalesce(v_siparis.birim, 'kg'),
      v_siparis.birim_fiyat,
      coalesce(v_siparis.para_birimi, 'TL'),
      CASE
        WHEN v_siparis.birim_fiyat IS NULL THEN NULL
        ELSE p_miktar * v_siparis.birim_fiyat
      END,
      v_siparis.tedarikci_id,
      p_firma_id,
      now(),
      now()
    )
    RETURNING id INTO v_stok_id;
  ELSE
    UPDATE public.iplik_stoklari
    SET
      miktar = coalesce(v_stok_miktar, 0) + p_miktar,
      birim_fiyat = coalesce(v_siparis.birim_fiyat, birim_fiyat),
      para_birimi = coalesce(v_siparis.para_birimi, para_birimi),
      toplam_deger = CASE
        WHEN coalesce(v_siparis.birim_fiyat, birim_fiyat) IS NULL THEN NULL
        ELSE (coalesce(v_stok_miktar, 0) + p_miktar) * coalesce(v_siparis.birim_fiyat, birim_fiyat)
      END,
      updated_at = now()
    WHERE id = v_stok_id
      AND firma_id = p_firma_id;
  END IF;

  INSERT INTO public.iplik_hareketleri (
    iplik_id,
    hareket_tipi,
    miktar,
    aciklama,
    firma_id,
    created_at,
    updated_at
  )
  VALUES (
    v_stok_id,
    'giris',
    p_miktar,
    'Siparis teslimatindan otomatik stok girisi - ' || coalesce(v_siparis.siparis_no, ''),
    p_firma_id,
    now(),
    now()
  );

  INSERT INTO public.iplik_siparis_teslimatlar (
    siparis_id,
    firma_id,
    teslim_kg,
    iplik_lotu,
    gelis_tarihi,
    teslimat_durumu,
    kalite_durumu,
    aciklama,
    created_at,
    updated_at
  )
  VALUES (
    p_siparis_id,
    p_firma_id,
    p_miktar,
    NULLIF(p_lot_no, ''),
    p_teslimat_tarihi,
    CASE WHEN v_teslim_edildi THEN 'tam_teslimat' ELSE 'kismi_teslimat' END,
    p_kalite_durumu,
    p_aciklama,
    now(),
    now()
  );

  RETURN jsonb_build_object(
    'siparis_id', p_siparis_id,
    'stok_id', v_stok_id,
    'teslim_yuzdesi', v_teslim_yuzdesi,
    'teslim_edildi', v_teslim_edildi
  );
END;
$$;

DROP VIEW IF EXISTS public.v_siparis_takip CASCADE;

CREATE VIEW public.v_siparis_takip AS
SELECT
  s.id,
  s.firma_id,
  s.siparis_no,
  s.marka,
  s.iplik_adi,
  s.renk,
  s.miktar,
  s.birim,
  s.teslim_miktari,
  s.teslim_yuzdesi,
  s.birim_fiyat,
  s.para_birimi,
  s.toplam_tutar,
  s.termin_tarihi,
  s.teslim_tarihi,
  s.lot_no,
  s.kalite_durumu,
  s.siparis_tarihi,
  s.durum,
  s.aciklama,
  s.teslim_edildi,
  s.created_at,
  s.updated_at,
  t.sirket AS tedarikci_adi,
  t.telefon AS tedarikci_telefon,
  s.tedarikci_id,
  o.sirket AS orgu_firmasi_adi,
  o.telefon AS orgu_firmasi_telefon,
  s.orgu_firmasi_id,
  CASE
    WHEN s.teslim_edildi = true THEN 'tamamlandi'
    WHEN s.termin_tarihi IS NOT NULL AND s.termin_tarihi < CURRENT_DATE AND s.teslim_edildi != true THEN 'gecikti'
    ELSE 'beklemede'
  END AS takip_durumu
FROM public.iplik_siparisleri s
LEFT JOIN public.tedarikciler t ON s.tedarikci_id = t.id AND s.firma_id = t.firma_id
LEFT JOIN public.tedarikciler o ON s.orgu_firmasi_id = o.id AND s.firma_id = o.firma_id;
