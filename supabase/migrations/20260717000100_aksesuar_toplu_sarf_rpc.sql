-- Aksesuar depo toplu sarf islemini tek transaction icinde kaydeder.

CREATE OR REPLACE FUNCTION public.aksesuar_toplu_sarf_kaydet(
  p_firma_id uuid,
  p_model_id uuid,
  p_tedarikci_adi text,
  p_aciklama text,
  p_satirlar jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_satir jsonb;
  v_beden_id uuid;
  v_aksesuar_id uuid;
  v_miktar integer;
  v_mevcut_stok integer;
  v_yeni_stok integer;
  v_islenen_bedenler uuid[] := ARRAY[]::uuid[];
  v_etkilenen_aksesuarlar uuid[] := ARRAY[]::uuid[];
  v_islem_sayisi integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Oturum acik degil';
  END IF;

  IF p_firma_id IS NULL OR NOT public.has_firma_access(p_firma_id) THEN
    RAISE EXCEPTION 'Bu firma icin islem yetkiniz yok';
  END IF;

  IF p_model_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.triko_takip t
    WHERE t.id = p_model_id
      AND t.firma_id = p_firma_id
  ) THEN
    RAISE EXCEPTION 'Model bulunamadi';
  END IF;

  IF coalesce(btrim(p_tedarikci_adi), '') = '' THEN
    RAISE EXCEPTION 'Tedarikci zorunludur';
  END IF;

  IF p_satirlar IS NULL
     OR jsonb_typeof(p_satirlar) <> 'array'
     OR jsonb_array_length(p_satirlar) = 0 THEN
    RAISE EXCEPTION 'En az bir aksesuar secilmelidir';
  END IF;

  FOR v_satir IN SELECT value FROM jsonb_array_elements(p_satirlar)
  LOOP
    BEGIN
      v_beden_id := NULLIF(v_satir->>'aksesuar_beden_id', '')::uuid;
      v_aksesuar_id := NULLIF(v_satir->>'aksesuar_id', '')::uuid;
      v_miktar := NULLIF(v_satir->>'miktar', '')::integer;
    EXCEPTION WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'Gecersiz toplu sarf satiri';
    END;

    IF v_beden_id IS NULL OR v_aksesuar_id IS NULL THEN
      RAISE EXCEPTION 'Aksesuar ve beden bilgisi zorunludur';
    END IF;

    IF v_miktar IS NULL OR v_miktar <= 0 THEN
      RAISE EXCEPTION 'Sarf miktari pozitif tam sayi olmalidir';
    END IF;

    IF v_beden_id = ANY(v_islenen_bedenler) THEN
      RAISE EXCEPTION 'Ayni aksesuar bedeni birden fazla kez secilemez';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.model_aksesuar ma
      WHERE ma.firma_id = p_firma_id
        AND ma.model_id = p_model_id
        AND ma.aksesuar_id = v_aksesuar_id
    ) THEN
      RAISE EXCEPTION 'Secilen aksesuar modele tanimli degil';
    END IF;

    SELECT ab.stok_miktari
    INTO v_mevcut_stok
    FROM public.aksesuar_bedenler ab
    JOIN public.aksesuarlar a ON a.id = ab.aksesuar_id
    WHERE ab.id = v_beden_id
      AND ab.aksesuar_id = v_aksesuar_id
      AND ab.firma_id = p_firma_id
      AND a.firma_id = p_firma_id
      AND ab.durum = 'aktif'
      AND a.durum = 'aktif'
    FOR UPDATE OF ab;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Aktif aksesuar stok satiri bulunamadi';
    END IF;

    IF v_miktar > v_mevcut_stok THEN
      RAISE EXCEPTION 'Yetersiz stok. Mevcut: %, istenen: %',
        v_mevcut_stok, v_miktar;
    END IF;

    v_yeni_stok := v_mevcut_stok - v_miktar;

    UPDATE public.aksesuar_bedenler
    SET stok_miktari = v_yeni_stok,
        updated_at = now()
    WHERE id = v_beden_id
      AND firma_id = p_firma_id;

    INSERT INTO public.aksesuar_stok_hareketleri (
      aksesuar_beden_id,
      hareket_tipi,
      miktar,
      onceki_stok,
      yeni_stok,
      model_id,
      aciklama,
      kullanici_id,
      firma_id,
      tedarikci_adi
    ) VALUES (
      v_beden_id,
      'cikis',
      v_miktar,
      v_mevcut_stok,
      v_yeni_stok,
      p_model_id,
      NULLIF(btrim(p_aciklama), ''),
      auth.uid(),
      p_firma_id,
      btrim(p_tedarikci_adi)
    );

    v_islenen_bedenler := array_append(v_islenen_bedenler, v_beden_id);
    IF NOT v_aksesuar_id = ANY(v_etkilenen_aksesuarlar) THEN
      v_etkilenen_aksesuarlar := array_append(
        v_etkilenen_aksesuarlar,
        v_aksesuar_id
      );
    END IF;
    v_islem_sayisi := v_islem_sayisi + 1;
  END LOOP;

  FOREACH v_aksesuar_id IN ARRAY v_etkilenen_aksesuarlar
  LOOP
    UPDATE public.aksesuarlar a
    SET miktar = (
          SELECT coalesce(sum(ab.stok_miktari), 0)
          FROM public.aksesuar_bedenler ab
          WHERE ab.aksesuar_id = a.id
            AND ab.firma_id = p_firma_id
            AND ab.durum = 'aktif'
        ),
        updated_at = now()
    WHERE a.id = v_aksesuar_id
      AND a.firma_id = p_firma_id;
  END LOOP;

  RETURN jsonb_build_object(
    'islem_sayisi', v_islem_sayisi,
    'aksesuar_sayisi', cardinality(v_etkilenen_aksesuarlar)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.aksesuar_toplu_sarf_kaydet(
  uuid, uuid, text, text, jsonb
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.aksesuar_toplu_sarf_kaydet(
  uuid, uuid, text, text, jsonb
) TO authenticated;
