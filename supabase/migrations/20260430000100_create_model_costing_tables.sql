-- Model costing and profitability foundation.
-- Adds target / plan / actual cost tables without changing existing model flows.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.safe_numeric(p_value text)
RETURNS numeric AS $$
DECLARE
    v_text text;
BEGIN
    v_text := nullif(trim(coalesce(p_value, '')), '');
    IF v_text IS NULL THEN
        RETURN 0;
    END IF;

    v_text := regexp_replace(v_text, '[^0-9,.-]', '', 'g');
    IF position(',' in v_text) > 0 AND position('.' in v_text) > 0 THEN
        v_text := replace(replace(v_text, '.', ''), ',', '.');
    ELSIF position(',' in v_text) > 0 THEN
        v_text := replace(v_text, ',', '.');
    ELSIF v_text ~ '^-?[0-9]{1,3}(\.[0-9]{3})+$' THEN
        v_text := replace(v_text, '.', '');
    END IF;
    IF v_text !~ '^-?[0-9]+(\.[0-9]+)?$' THEN
        RETURN 0;
    END IF;

    RETURN v_text::numeric;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.safe_int(p_value text)
RETURNS integer AS $$
DECLARE
    v_num numeric;
BEGIN
    v_num := public.safe_numeric(p_value);
    RETURN coalesce(v_num::integer, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE TABLE IF NOT EXISTS public.model_maliyet_planlari (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    versiyon_no integer NOT NULL DEFAULT 1,
    durum text NOT NULL DEFAULT 'aktif'
        CHECK (durum IN ('taslak', 'aktif', 'arsiv')),
    plan_tipi text NOT NULL DEFAULT 'plan'
        CHECK (plan_tipi IN ('hedef', 'plan', 'revize')),
    para_birimi text NOT NULL DEFAULT 'TRY',
    kur numeric(18, 6) NOT NULL DEFAULT 1,
    hedef_kar_marji numeric(7, 2) NOT NULL DEFAULT 0,
    hedef_satis_fiyati numeric(18, 4) NOT NULL DEFAULT 0,
    plan_adet integer NOT NULL DEFAULT 0,
    plan_fire_orani numeric(7, 2) NOT NULL DEFAULT 0,
    plan_birim_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    plan_toplam_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    plan_satis_fiyati numeric(18, 4) NOT NULL DEFAULT 0,
    notlar text,
    created_by uuid DEFAULT auth.uid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (model_id, versiyon_no)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_model_maliyet_planlari_aktif
ON public.model_maliyet_planlari(model_id)
WHERE durum = 'aktif';

CREATE INDEX IF NOT EXISTS idx_model_maliyet_planlari_firma
ON public.model_maliyet_planlari(firma_id);

CREATE INDEX IF NOT EXISTS idx_model_maliyet_planlari_model
ON public.model_maliyet_planlari(model_id);

CREATE TABLE IF NOT EXISTS public.model_maliyet_kalemleri (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    plan_id uuid NOT NULL REFERENCES public.model_maliyet_planlari(id) ON DELETE CASCADE,
    kalem_tipi text NOT NULL
        CHECK (kalem_tipi IN (
            'iplik',
            'orgu',
            'dikim',
            'utu',
            'yikama',
            'ilik_dugme',
            'fermuar',
            'baski_nakis',
            'aksesuar',
            'genel_aksesuar',
            'genel_gider',
            'paketleme',
            'diger'
        )),
    aciklama text,
    miktar numeric(18, 4) NOT NULL DEFAULT 1,
    birim text NOT NULL DEFAULT 'adet',
    birim_fiyat numeric(18, 4) NOT NULL DEFAULT 0,
    plan_birim_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    plan_toplam_tutar numeric(18, 4) NOT NULL DEFAULT 0,
    kaynak text NOT NULL DEFAULT 'manuel'
        CHECK (kaynak IN ('manuel', 'model', 'stok', 'fatura', 'uretim')),
    sira_no integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_model_maliyet_kalemleri_plan
ON public.model_maliyet_kalemleri(plan_id);

CREATE INDEX IF NOT EXISTS idx_model_maliyet_kalemleri_model
ON public.model_maliyet_kalemleri(model_id);

CREATE TABLE IF NOT EXISTS public.model_maliyet_gerceklesen (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    plan_id uuid REFERENCES public.model_maliyet_planlari(id) ON DELETE SET NULL,
    kalem_tipi text NOT NULL,
    kaynak text NOT NULL DEFAULT 'manuel'
        CHECK (kaynak IN ('manuel', 'stok', 'fatura', 'uretim', 'sevkiyat')),
    belge_turu text,
    belge_id text,
    miktar numeric(18, 4) NOT NULL DEFAULT 0,
    birim text NOT NULL DEFAULT 'adet',
    birim_fiyat numeric(18, 4) NOT NULL DEFAULT 0,
    toplam_tutar numeric(18, 4) NOT NULL DEFAULT 0,
    fire_adedi integer NOT NULL DEFAULT 0,
    tarih date NOT NULL DEFAULT current_date,
    aciklama text,
    created_by uuid DEFAULT auth.uid(),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_model_maliyet_gerceklesen_model
ON public.model_maliyet_gerceklesen(model_id);

CREATE INDEX IF NOT EXISTS idx_model_maliyet_gerceklesen_tarih
ON public.model_maliyet_gerceklesen(firma_id, tarih);

CREATE TABLE IF NOT EXISTS public.model_karlilik_ozetleri (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
    model_id uuid NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    aktif_plan_id uuid REFERENCES public.model_maliyet_planlari(id) ON DELETE SET NULL,
    siparis_adedi integer NOT NULL DEFAULT 0,
    tamamlanan_adet integer NOT NULL DEFAULT 0,
    fire_adedi integer NOT NULL DEFAULT 0,
    plan_birim_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    gercek_birim_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    plan_toplam_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    gercek_toplam_maliyet numeric(18, 4) NOT NULL DEFAULT 0,
    satis_birim_fiyati numeric(18, 4) NOT NULL DEFAULT 0,
    satis_geliri numeric(18, 4) NOT NULL DEFAULT 0,
    brut_kar numeric(18, 4) NOT NULL DEFAULT 0,
    brut_kar_marji numeric(8, 4) NOT NULL DEFAULT 0,
    maliyet_sapmasi numeric(18, 4) NOT NULL DEFAULT 0,
    maliyet_sapma_orani numeric(8, 4) NOT NULL DEFAULT 0,
    fire_orani numeric(8, 4) NOT NULL DEFAULT 0,
    durum text NOT NULL DEFAULT 'fiyat_eksik'
        CHECK (durum IN ('hedefte', 'hedef_alti', 'zarar_riski', 'fiyat_eksik')),
    hesaplama_tarihi timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (model_id)
);

CREATE INDEX IF NOT EXISTS idx_model_karlilik_ozetleri_firma
ON public.model_karlilik_ozetleri(firma_id);

CREATE OR REPLACE FUNCTION public.model_karlilik_ozeti_yenile(p_model_id uuid)
RETURNS public.model_karlilik_ozetleri AS $$
DECLARE
    v_model public.triko_takip%ROWTYPE;
    v_model_json jsonb;
    v_plan public.model_maliyet_planlari%ROWTYPE;
    v_plan_id uuid;
    v_firma_id uuid;
    v_siparis_adedi integer := 0;
    v_tamamlanan_adet integer := 0;
    v_fire_adedi integer := 0;
    v_plan_birim_maliyet numeric := 0;
    v_plan_toplam_maliyet numeric := 0;
    v_gercek_toplam_maliyet numeric := 0;
    v_gercek_birim_maliyet numeric := 0;
    v_satis_birim_fiyati numeric := 0;
    v_satis_geliri numeric := 0;
    v_brut_kar numeric := 0;
    v_brut_kar_marji numeric := 0;
    v_maliyet_sapmasi numeric := 0;
    v_maliyet_sapma_orani numeric := 0;
    v_fire_orani numeric := 0;
    v_hedef_kar_marji numeric := 0;
    v_maliyet_yuklenen_adet integer := 0;
    v_durum text := 'fiyat_eksik';
    v_result public.model_karlilik_ozetleri%ROWTYPE;
BEGIN
    SELECT *
    INTO v_model
    FROM public.triko_takip
    WHERE id = p_model_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Model bulunamadi: %', p_model_id;
    END IF;

    v_model_json := to_jsonb(v_model);
    v_firma_id := (v_model_json ->> 'firma_id')::uuid;

    SELECT *
    INTO v_plan
    FROM public.model_maliyet_planlari
    WHERE model_id = p_model_id
    ORDER BY (durum = 'aktif') DESC, versiyon_no DESC, created_at DESC
    LIMIT 1;

    IF FOUND THEN
        v_plan_id := v_plan.id;
        v_hedef_kar_marji := coalesce(v_plan.hedef_kar_marji, 0);
        v_siparis_adedi := greatest(coalesce(v_plan.plan_adet, 0), 0);

        SELECT coalesce(nullif(sum(plan_birim_maliyet), 0), v_plan.plan_birim_maliyet, 0)
        INTO v_plan_birim_maliyet
        FROM public.model_maliyet_kalemleri
        WHERE plan_id = v_plan.id;
    ELSE
        v_hedef_kar_marji := public.safe_numeric(v_model_json ->> 'kar_marji');
        v_siparis_adedi := coalesce(
            nullif(public.safe_int(v_model_json ->> 'toplam_adet'), 0),
            nullif(public.safe_int(v_model_json ->> 'adet'), 0),
            0
        );

        v_plan_birim_maliyet :=
            public.safe_numeric(v_model_json ->> 'iplik_maliyeti') +
            public.safe_numeric(v_model_json ->> 'orgu_fiyat') +
            public.safe_numeric(v_model_json ->> 'dikim_fiyat') +
            public.safe_numeric(v_model_json ->> 'utu_fiyat') +
            public.safe_numeric(v_model_json ->> 'yikama_fiyat') +
            public.safe_numeric(v_model_json ->> 'ilik_dugme_fiyat') +
            public.safe_numeric(v_model_json ->> 'fermuar_fiyat') +
            public.safe_numeric(v_model_json ->> 'aksesuar_fiyat') +
            public.safe_numeric(v_model_json ->> 'genel_aksesuar_fiyat') +
            public.safe_numeric(v_model_json ->> 'genel_gider_fiyat');
    END IF;

    IF v_siparis_adedi <= 0 THEN
        v_siparis_adedi := coalesce(
            nullif(public.safe_int(v_model_json ->> 'toplam_adet'), 0),
            nullif(public.safe_int(v_model_json ->> 'adet'), 0),
            0
        );
    END IF;

    v_tamamlanan_adet := public.safe_int(v_model_json ->> 'tamamlanan_adet');

    IF v_tamamlanan_adet <= 0 THEN
        SELECT coalesce(asama_toplam, 0)
        INTO v_tamamlanan_adet
        FROM (
            SELECT
                asama_key,
                asama_toplam,
                CASE asama_key
                    WHEN 'sevkiyat' THEN 100
                    WHEN 'yukleme' THEN 98
                    WHEN 'depolama' THEN 96
                    WHEN 'paketleme' THEN 94
                    WHEN 'kalite_kontrol' THEN 92
                    WHEN 'kalite' THEN 90
                    WHEN 'test' THEN 88
                    WHEN 'utu' THEN 86
                    WHEN 'utu_pres' THEN 84
                    WHEN 'ilik_dugme' THEN 82
                    WHEN 'yikama' THEN 80
                    WHEN 'son_terbiye' THEN 78
                    WHEN 'terbiye' THEN 76
                    WHEN 'nakis' THEN 74
                    WHEN 'baski' THEN 72
                    WHEN 'konfeksiyon' THEN 70
                    WHEN 'dikim' THEN 68
                    WHEN 'kesim' THEN 66
                    WHEN 'orgu' THEN 64
                    WHEN 'orme' THEN 62
                    WHEN 'dokuma' THEN 60
                    WHEN 'boyama' THEN 58
                    WHEN 'iplik_hazirlama' THEN 56
                    ELSE 0
                END AS asama_sirasi
            FROM (
                SELECT
                    coalesce(kayit_json ->> 'asama', 'genel') AS asama_key,
                    sum(coalesce(
                        nullif(public.safe_int(kayit_json ->> 'kabul_edilen_adet'), 0),
                        nullif(public.safe_int(kayit_json ->> 'tamamlanan_adet'), 0),
                        nullif(public.safe_int(kayit_json ->> 'uretilen_adet'), 0),
                        0
                    ))::integer AS asama_toplam
                FROM (
                    SELECT to_jsonb(uk) AS kayit_json
                    FROM public.uretim_kayitlari uk
                    WHERE uk.model_id = p_model_id
                ) q
                GROUP BY coalesce(kayit_json ->> 'asama', 'genel')
            ) totals
            WHERE asama_toplam > 0
            ORDER BY asama_sirasi DESC, asama_toplam DESC
            LIMIT 1
        ) ranked;
    END IF;
    v_tamamlanan_adet := coalesce(v_tamamlanan_adet, 0);

    SELECT public.safe_int(v_model_json ->> 'fire_adet') +
           coalesce(sum(public.safe_int(kayit_json ->> 'fire_adet')), 0)::integer
    INTO v_fire_adedi
    FROM (
        SELECT to_jsonb(uk) AS kayit_json
        FROM public.uretim_kayitlari uk
        WHERE uk.model_id = p_model_id
    ) q;

    v_plan_toplam_maliyet := v_plan_birim_maliyet * v_siparis_adedi;

    SELECT coalesce(sum(toplam_tutar), 0)
    INTO v_gercek_toplam_maliyet
    FROM public.model_maliyet_gerceklesen
    WHERE model_id = p_model_id;

    IF v_gercek_toplam_maliyet <= 0 THEN
        v_maliyet_yuklenen_adet := CASE
            WHEN v_tamamlanan_adet > 0 THEN v_tamamlanan_adet + v_fire_adedi
            ELSE v_siparis_adedi + v_fire_adedi
        END;
        v_gercek_toplam_maliyet := v_plan_birim_maliyet * v_maliyet_yuklenen_adet;
    END IF;

    v_gercek_birim_maliyet := CASE
        WHEN v_tamamlanan_adet > 0 THEN v_gercek_toplam_maliyet / v_tamamlanan_adet
        ELSE v_plan_birim_maliyet
    END;

    v_satis_birim_fiyati := coalesce(
        nullif(public.safe_numeric(v_model_json ->> 'pesin_fiyat'), 0),
        nullif(public.safe_numeric(v_model_json ->> 'satis_fiyati'), 0),
        nullif(public.safe_numeric(v_model_json ->> 'final_fiyat'), 0),
        nullif(public.safe_numeric(v_model_json ->> 'birim_satis_fiyati'), 0),
        nullif(coalesce(v_plan.plan_satis_fiyati, 0), 0),
        v_plan_birim_maliyet * (1 + v_hedef_kar_marji / 100)
    );

    v_satis_geliri := v_satis_birim_fiyati *
        CASE WHEN v_tamamlanan_adet > 0 THEN v_tamamlanan_adet ELSE v_siparis_adedi END;
    v_brut_kar := v_satis_geliri - v_gercek_toplam_maliyet;
    v_brut_kar_marji := CASE WHEN v_satis_geliri > 0 THEN (v_brut_kar / v_satis_geliri) * 100 ELSE 0 END;
    v_maliyet_sapmasi := v_gercek_birim_maliyet - v_plan_birim_maliyet;
    v_maliyet_sapma_orani := CASE WHEN v_plan_birim_maliyet > 0 THEN (v_maliyet_sapmasi / v_plan_birim_maliyet) * 100 ELSE 0 END;
    v_fire_orani := CASE WHEN v_siparis_adedi > 0 THEN (v_fire_adedi::numeric / v_siparis_adedi) * 100 ELSE 0 END;

    v_durum := CASE
        WHEN v_satis_birim_fiyati <= 0 THEN 'fiyat_eksik'
        WHEN v_brut_kar < 0 THEN 'zarar_riski'
        WHEN v_brut_kar_marji < v_hedef_kar_marji THEN 'hedef_alti'
        ELSE 'hedefte'
    END;

    INSERT INTO public.model_karlilik_ozetleri (
        firma_id,
        model_id,
        aktif_plan_id,
        siparis_adedi,
        tamamlanan_adet,
        fire_adedi,
        plan_birim_maliyet,
        gercek_birim_maliyet,
        plan_toplam_maliyet,
        gercek_toplam_maliyet,
        satis_birim_fiyati,
        satis_geliri,
        brut_kar,
        brut_kar_marji,
        maliyet_sapmasi,
        maliyet_sapma_orani,
        fire_orani,
        durum,
        hesaplama_tarihi,
        updated_at
    )
    VALUES (
        v_firma_id,
        p_model_id,
        v_plan_id,
        v_siparis_adedi,
        v_tamamlanan_adet,
        v_fire_adedi,
        v_plan_birim_maliyet,
        v_gercek_birim_maliyet,
        v_plan_toplam_maliyet,
        v_gercek_toplam_maliyet,
        v_satis_birim_fiyati,
        v_satis_geliri,
        v_brut_kar,
        v_brut_kar_marji,
        v_maliyet_sapmasi,
        v_maliyet_sapma_orani,
        v_fire_orani,
        v_durum,
        now(),
        now()
    )
    ON CONFLICT (model_id)
    DO UPDATE SET
        firma_id = excluded.firma_id,
        aktif_plan_id = excluded.aktif_plan_id,
        siparis_adedi = excluded.siparis_adedi,
        tamamlanan_adet = excluded.tamamlanan_adet,
        fire_adedi = excluded.fire_adedi,
        plan_birim_maliyet = excluded.plan_birim_maliyet,
        gercek_birim_maliyet = excluded.gercek_birim_maliyet,
        plan_toplam_maliyet = excluded.plan_toplam_maliyet,
        gercek_toplam_maliyet = excluded.gercek_toplam_maliyet,
        satis_birim_fiyati = excluded.satis_birim_fiyati,
        satis_geliri = excluded.satis_geliri,
        brut_kar = excluded.brut_kar,
        brut_kar_marji = excluded.brut_kar_marji,
        maliyet_sapmasi = excluded.maliyet_sapmasi,
        maliyet_sapma_orani = excluded.maliyet_sapma_orani,
        fire_orani = excluded.fire_orani,
        durum = excluded.durum,
        hesaplama_tarihi = now(),
        updated_at = now()
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.model_karlilik_ozeti_trigger()
RETURNS trigger AS $$
DECLARE
    v_model_id uuid;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_model_id := OLD.model_id;
        PERFORM public.model_karlilik_ozeti_yenile(v_model_id);
        RETURN OLD;
    END IF;

    v_model_id := NEW.model_id;
    PERFORM public.model_karlilik_ozeti_yenile(v_model_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_model_maliyet_planlari_ozet ON public.model_maliyet_planlari;
CREATE TRIGGER trg_model_maliyet_planlari_ozet
AFTER INSERT OR UPDATE OR DELETE ON public.model_maliyet_planlari
FOR EACH ROW EXECUTE FUNCTION public.model_karlilik_ozeti_trigger();

DROP TRIGGER IF EXISTS trg_model_maliyet_kalemleri_ozet ON public.model_maliyet_kalemleri;
CREATE TRIGGER trg_model_maliyet_kalemleri_ozet
AFTER INSERT OR UPDATE OR DELETE ON public.model_maliyet_kalemleri
FOR EACH ROW EXECUTE FUNCTION public.model_karlilik_ozeti_trigger();

DROP TRIGGER IF EXISTS trg_model_maliyet_gerceklesen_ozet ON public.model_maliyet_gerceklesen;
CREATE TRIGGER trg_model_maliyet_gerceklesen_ozet
AFTER INSERT OR UPDATE OR DELETE ON public.model_maliyet_gerceklesen
FOR EACH ROW EXECUTE FUNCTION public.model_karlilik_ozeti_trigger();

ALTER TABLE public.model_maliyet_planlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_maliyet_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_maliyet_gerceklesen ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_karlilik_ozetleri ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS model_maliyet_planlari_select ON public.model_maliyet_planlari;
CREATE POLICY model_maliyet_planlari_select
ON public.model_maliyet_planlari FOR SELECT
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_planlari_insert ON public.model_maliyet_planlari;
CREATE POLICY model_maliyet_planlari_insert
ON public.model_maliyet_planlari FOR INSERT
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_planlari_update ON public.model_maliyet_planlari;
CREATE POLICY model_maliyet_planlari_update
ON public.model_maliyet_planlari FOR UPDATE
USING (public.has_firma_access(firma_id))
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_planlari_delete ON public.model_maliyet_planlari;
CREATE POLICY model_maliyet_planlari_delete
ON public.model_maliyet_planlari FOR DELETE
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_kalemleri_select ON public.model_maliyet_kalemleri;
CREATE POLICY model_maliyet_kalemleri_select
ON public.model_maliyet_kalemleri FOR SELECT
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_kalemleri_insert ON public.model_maliyet_kalemleri;
CREATE POLICY model_maliyet_kalemleri_insert
ON public.model_maliyet_kalemleri FOR INSERT
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_kalemleri_update ON public.model_maliyet_kalemleri;
CREATE POLICY model_maliyet_kalemleri_update
ON public.model_maliyet_kalemleri FOR UPDATE
USING (public.has_firma_access(firma_id))
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_kalemleri_delete ON public.model_maliyet_kalemleri;
CREATE POLICY model_maliyet_kalemleri_delete
ON public.model_maliyet_kalemleri FOR DELETE
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_gerceklesen_select ON public.model_maliyet_gerceklesen;
CREATE POLICY model_maliyet_gerceklesen_select
ON public.model_maliyet_gerceklesen FOR SELECT
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_gerceklesen_insert ON public.model_maliyet_gerceklesen;
CREATE POLICY model_maliyet_gerceklesen_insert
ON public.model_maliyet_gerceklesen FOR INSERT
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_gerceklesen_update ON public.model_maliyet_gerceklesen;
CREATE POLICY model_maliyet_gerceklesen_update
ON public.model_maliyet_gerceklesen FOR UPDATE
USING (public.has_firma_access(firma_id))
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_maliyet_gerceklesen_delete ON public.model_maliyet_gerceklesen;
CREATE POLICY model_maliyet_gerceklesen_delete
ON public.model_maliyet_gerceklesen FOR DELETE
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_karlilik_ozetleri_select ON public.model_karlilik_ozetleri;
CREATE POLICY model_karlilik_ozetleri_select
ON public.model_karlilik_ozetleri FOR SELECT
USING (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_karlilik_ozetleri_insert ON public.model_karlilik_ozetleri;
CREATE POLICY model_karlilik_ozetleri_insert
ON public.model_karlilik_ozetleri FOR INSERT
WITH CHECK (public.has_firma_access(firma_id));

DROP POLICY IF EXISTS model_karlilik_ozetleri_update ON public.model_karlilik_ozetleri;
CREATE POLICY model_karlilik_ozetleri_update
ON public.model_karlilik_ozetleri FOR UPDATE
USING (public.has_firma_access(firma_id))
WITH CHECK (public.has_firma_access(firma_id));

REVOKE ALL ON FUNCTION public.model_karlilik_ozeti_yenile(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.model_karlilik_ozeti_yenile(uuid) TO authenticated;
