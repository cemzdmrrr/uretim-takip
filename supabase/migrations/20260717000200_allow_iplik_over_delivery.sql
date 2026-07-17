-- Siparis miktarini asan iplik teslimatlarini kabul eder.

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
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Oturum acik degil';
  END IF;

  IF p_firma_id IS NULL OR NOT public.has_firma_access(p_firma_id) THEN
    RAISE EXCEPTION 'Bu firma icin islem yetkiniz yok';
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
    durum = CASE
      WHEN v_teslim_edildi THEN 'teslim_edildi'
      ELSE coalesce(durum, 'beklemede')
    END,
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
    AND coalesce(tedarikci_id::text, '') =
        coalesce(v_siparis.tedarikci_id::text, '')
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
        ELSE (coalesce(v_stok_miktar, 0) + p_miktar) *
             coalesce(v_siparis.birim_fiyat, birim_fiyat)
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
    'Siparis teslimatindan otomatik stok girisi - ' ||
      coalesce(v_siparis.siparis_no, ''),
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
    'teslim_edildi', v_teslim_edildi,
    'fazla_teslim_miktari',
      greatest(v_toplam_teslim - coalesce(v_siparis.miktar, 0), 0)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.iplik_siparis_teslimat_kaydet(
  uuid, uuid, numeric, text, text, date, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.iplik_siparis_teslimat_kaydet(
  uuid, uuid, numeric, text, text, date, text
) TO authenticated;
