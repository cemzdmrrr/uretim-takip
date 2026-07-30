-- Iplik lokasyon dagilimi ve oturum bazli kor sayim.
CREATE TABLE public.iplik_lokasyonlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  kod text NOT NULL, ad text NOT NULL, aciklama text, aktif boolean NOT NULL DEFAULT true,
  sistem_lokasyonu boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(firma_id,kod)
);
CREATE TABLE public.iplik_stok_lokasyonlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  stok_id uuid NOT NULL REFERENCES public.iplik_stoklari(id) ON DELETE CASCADE,
  lokasyon_id uuid NOT NULL REFERENCES public.iplik_lokasyonlari(id), miktar numeric(12,2) NOT NULL DEFAULT 0 CHECK(miktar>=0),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(firma_id,stok_id,lokasyon_id)
);
CREATE TABLE public.iplik_sayim_oturumlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  sayim_no text NOT NULL, aciklama text, durum text NOT NULL DEFAULT 'taslak' CHECK(durum IN('taslak','tamamlandi','iptal')),
  acan_user_id uuid REFERENCES auth.users(id), kapatan_user_id uuid REFERENCES auth.users(id),
  acilis_tarihi timestamptz NOT NULL DEFAULT now(), kapanis_tarihi timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(firma_id,sayim_no)
);
CREATE TABLE public.iplik_sayim_oturum_lokasyonlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  sayim_id uuid NOT NULL REFERENCES public.iplik_sayim_oturumlari(id) ON DELETE CASCADE,
  lokasyon_id uuid NOT NULL REFERENCES public.iplik_lokasyonlari(id), UNIQUE(sayim_id,lokasyon_id)
);
CREATE TABLE public.iplik_sayim_satirlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), firma_id uuid NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  sayim_id uuid NOT NULL REFERENCES public.iplik_sayim_oturumlari(id) ON DELETE CASCADE,
  lokasyon_id uuid NOT NULL REFERENCES public.iplik_lokasyonlari(id), stok_id uuid NOT NULL REFERENCES public.iplik_stoklari(id) ON DELETE CASCADE,
  beklenen_miktar numeric(12,2) NOT NULL DEFAULT 0 CHECK(beklenen_miktar>=0), sayilan_miktar numeric(12,2) CHECK(sayilan_miktar>=0),
  sayan_user_id uuid REFERENCES auth.users(id), sayim_tarihi timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(sayim_id,lokasyon_id,stok_id)
);
ALTER TABLE public.iplik_hareketleri ADD COLUMN kaynak_lokasyon_id uuid REFERENCES public.iplik_lokasyonlari(id),
  ADD COLUMN hedef_lokasyon_id uuid REFERENCES public.iplik_lokasyonlari(id),
  ADD COLUMN sayim_oturum_id uuid REFERENCES public.iplik_sayim_oturumlari(id);
CREATE INDEX idx_iplik_stok_lokasyon_firma_stok ON public.iplik_stok_lokasyonlari(firma_id,stok_id);
CREATE INDEX idx_iplik_sayim_oturum_firma_durum ON public.iplik_sayim_oturumlari(firma_id,durum,created_at DESC);
CREATE INDEX idx_iplik_sayim_satir_sayim ON public.iplik_sayim_satirlari(firma_id,sayim_id);

INSERT INTO public.iplik_lokasyonlari(firma_id,kod,ad,aciklama,aktif,sistem_lokasyonu)
SELECT id,'LOKASYONSUZ','Lokasyonsuz','Sistem lokasyonu',true,true FROM public.firmalar ON CONFLICT(firma_id,kod) DO NOTHING;
INSERT INTO public.iplik_stok_lokasyonlari(firma_id,stok_id,lokasyon_id,miktar)
SELECT s.firma_id,s.id,l.id,coalesce(s.miktar,0) FROM public.iplik_stoklari s
JOIN public.iplik_lokasyonlari l ON l.firma_id=s.firma_id AND l.kod='LOKASYONSUZ'
WHERE NOT EXISTS(SELECT 1 FROM public.iplik_stok_lokasyonlari x WHERE x.firma_id=s.firma_id AND x.stok_id=s.id);

CREATE FUNCTION public.iplik_firma_uyesi(p_firma_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT auth.uid() IS NULL OR EXISTS(SELECT 1 FROM public.firma_kullanicilari fk WHERE fk.firma_id=p_firma_id AND fk.user_id=auth.uid() AND fk.aktif=true)
$$;
CREATE FUNCTION public.iplik_firma_yoneticisi(p_firma_id uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT auth.uid() IS NULL OR EXISTS(SELECT 1 FROM public.firma_kullanicilari fk WHERE fk.firma_id=p_firma_id AND fk.user_id=auth.uid() AND fk.aktif=true AND fk.rol IN('firma_sahibi','firma_admin'))
$$;
ALTER TABLE public.iplik_lokasyonlari ENABLE ROW LEVEL SECURITY; ALTER TABLE public.iplik_stok_lokasyonlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_sayim_oturumlari ENABLE ROW LEVEL SECURITY; ALTER TABLE public.iplik_sayim_oturum_lokasyonlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_sayim_satirlari ENABLE ROW LEVEL SECURITY;
CREATE POLICY iplik_firma_kapsami ON public.iplik_lokasyonlari FOR ALL USING(public.iplik_firma_uyesi(firma_id)) WITH CHECK(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_firma_kapsami ON public.iplik_stok_lokasyonlari FOR ALL USING(public.iplik_firma_uyesi(firma_id)) WITH CHECK(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_firma_kapsami ON public.iplik_sayim_oturumlari FOR ALL USING(public.iplik_firma_uyesi(firma_id)) WITH CHECK(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_firma_kapsami ON public.iplik_sayim_oturum_lokasyonlari FOR ALL USING(public.iplik_firma_uyesi(firma_id)) WITH CHECK(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_firma_kapsami ON public.iplik_sayim_satirlari FOR ALL USING(public.iplik_firma_uyesi(firma_id)) WITH CHECK(public.iplik_firma_uyesi(firma_id));

-- Sayim ve lokasyon tanimlarinda dogrudan yazma yalniz firma yoneticilerine aciktir.
DROP POLICY iplik_firma_kapsami ON public.iplik_lokasyonlari;
CREATE POLICY iplik_lokasyon_oku ON public.iplik_lokasyonlari FOR SELECT USING(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_lokasyon_yonet ON public.iplik_lokasyonlari FOR ALL USING(public.iplik_firma_yoneticisi(firma_id)) WITH CHECK(public.iplik_firma_yoneticisi(firma_id));
DROP POLICY iplik_firma_kapsami ON public.iplik_stok_lokasyonlari;
CREATE POLICY iplik_stok_lokasyon_oku ON public.iplik_stok_lokasyonlari FOR SELECT USING(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_stok_lokasyon_yonet ON public.iplik_stok_lokasyonlari FOR ALL USING(public.iplik_firma_yoneticisi(firma_id)) WITH CHECK(public.iplik_firma_yoneticisi(firma_id));
DROP POLICY iplik_firma_kapsami ON public.iplik_sayim_oturumlari;
DROP POLICY iplik_firma_kapsami ON public.iplik_sayim_oturum_lokasyonlari;
DROP POLICY iplik_firma_kapsami ON public.iplik_sayim_satirlari;
CREATE POLICY iplik_sayim_oku ON public.iplik_sayim_oturumlari FOR SELECT USING(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_sayim_yonet ON public.iplik_sayim_oturumlari FOR ALL USING(public.iplik_firma_yoneticisi(firma_id)) WITH CHECK(public.iplik_firma_yoneticisi(firma_id));
CREATE POLICY iplik_sayim_lokasyon_oku ON public.iplik_sayim_oturum_lokasyonlari FOR SELECT USING(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_sayim_lokasyon_yonet ON public.iplik_sayim_oturum_lokasyonlari FOR ALL USING(public.iplik_firma_yoneticisi(firma_id)) WITH CHECK(public.iplik_firma_yoneticisi(firma_id));
CREATE POLICY iplik_sayim_satir_oku ON public.iplik_sayim_satirlari FOR SELECT USING(public.iplik_firma_uyesi(firma_id));
CREATE POLICY iplik_sayim_satir_yonet ON public.iplik_sayim_satirlari FOR ALL USING(public.iplik_firma_yoneticisi(firma_id)) WITH CHECK(public.iplik_firma_yoneticisi(firma_id));

CREATE FUNCTION public.iplik_lokasyonlu_stok_hareket_kaydet(
 p_firma_id uuid,p_iplik_id uuid DEFAULT NULL,p_stok_data jsonb DEFAULT NULL,p_hareket_tipi text DEFAULT 'giris',
 p_miktar numeric DEFAULT 0,p_aciklama text DEFAULT NULL,p_model_id uuid DEFAULT NULL,
 p_kaynak_lokasyon_id uuid DEFAULT NULL,p_hedef_lokasyon_id uuid DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r jsonb; sid uuid; lm numeric;
BEGIN
 IF NOT public.iplik_firma_uyesi(p_firma_id) THEN RAISE EXCEPTION 'Firma erisim yetkisi yok'; END IF;
 IF p_miktar<=0 THEN RAISE EXCEPTION 'Gecerli miktar girin'; END IF;
 IF p_kaynak_lokasyon_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.iplik_lokasyonlari WHERE id=p_kaynak_lokasyon_id AND firma_id=p_firma_id) THEN RAISE EXCEPTION 'Kaynak lokasyon firmaya ait degil'; END IF;
 IF p_hedef_lokasyon_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.iplik_lokasyonlari WHERE id=p_hedef_lokasyon_id AND firma_id=p_firma_id AND aktif=true) THEN RAISE EXCEPTION 'Hedef lokasyon aktif degil veya firmaya ait degil'; END IF;
 IF p_hareket_tipi='transfer' THEN
  IF p_iplik_id IS NULL OR p_kaynak_lokasyon_id IS NULL OR p_hedef_lokasyon_id IS NULL OR p_kaynak_lokasyon_id=p_hedef_lokasyon_id THEN RAISE EXCEPTION 'Kaynak ve hedef lokasyon zorunludur'; END IF;
  SELECT miktar INTO lm FROM public.iplik_stok_lokasyonlari WHERE firma_id=p_firma_id AND stok_id=p_iplik_id AND lokasyon_id=p_kaynak_lokasyon_id FOR UPDATE;
  IF coalesce(lm,0)<p_miktar THEN RAISE EXCEPTION 'Kaynak lokasyon miktari yetersiz'; END IF;
  UPDATE public.iplik_stok_lokasyonlari SET miktar=miktar-p_miktar,updated_at=now() WHERE firma_id=p_firma_id AND stok_id=p_iplik_id AND lokasyon_id=p_kaynak_lokasyon_id;
  INSERT INTO public.iplik_stok_lokasyonlari(firma_id,stok_id,lokasyon_id,miktar) VALUES(p_firma_id,p_iplik_id,p_hedef_lokasyon_id,p_miktar)
   ON CONFLICT(firma_id,stok_id,lokasyon_id) DO UPDATE SET miktar=public.iplik_stok_lokasyonlari.miktar+EXCLUDED.miktar,updated_at=now();
  INSERT INTO public.iplik_hareketleri(iplik_id,hareket_tipi,miktar,aciklama,firma_id,kaynak_lokasyon_id,hedef_lokasyon_id,created_at,updated_at)
   VALUES(p_iplik_id,'transfer',p_miktar,p_aciklama,p_firma_id,p_kaynak_lokasyon_id,p_hedef_lokasyon_id,now(),now());
  RETURN jsonb_build_object('iplik_id',p_iplik_id,'yeni_miktar',(SELECT miktar FROM public.iplik_stoklari WHERE id=p_iplik_id));
 END IF;
 IF p_hareket_tipi='giris' AND p_hedef_lokasyon_id IS NULL THEN RAISE EXCEPTION 'Hedef lokasyon zorunludur'; END IF;
 IF p_hareket_tipi='cikis' THEN
  IF p_kaynak_lokasyon_id IS NULL THEN RAISE EXCEPTION 'Kaynak lokasyon zorunludur'; END IF;
  SELECT miktar INTO lm FROM public.iplik_stok_lokasyonlari WHERE firma_id=p_firma_id AND stok_id=p_iplik_id AND lokasyon_id=p_kaynak_lokasyon_id FOR UPDATE;
  IF coalesce(lm,0)<p_miktar THEN RAISE EXCEPTION 'Kaynak lokasyon miktari yetersiz'; END IF;
 END IF;
 r:=public.iplik_rezervasyonlu_stok_hareket_kaydet(p_firma_id,p_iplik_id,p_stok_data,p_hareket_tipi,p_miktar,p_aciklama,p_model_id); sid:=(r->>'iplik_id')::uuid;
 IF p_hareket_tipi='giris' THEN
  INSERT INTO public.iplik_stok_lokasyonlari(firma_id,stok_id,lokasyon_id,miktar) VALUES(p_firma_id,sid,p_hedef_lokasyon_id,p_miktar)
   ON CONFLICT(firma_id,stok_id,lokasyon_id) DO UPDATE SET miktar=public.iplik_stok_lokasyonlari.miktar+EXCLUDED.miktar,updated_at=now();
 ELSIF p_hareket_tipi='cikis' THEN UPDATE public.iplik_stok_lokasyonlari SET miktar=miktar-p_miktar,updated_at=now() WHERE firma_id=p_firma_id AND stok_id=sid AND lokasyon_id=p_kaynak_lokasyon_id; END IF;
 UPDATE public.iplik_hareketleri SET kaynak_lokasyon_id=p_kaynak_lokasyon_id,hedef_lokasyon_id=p_hedef_lokasyon_id WHERE id=(SELECT id FROM public.iplik_hareketleri WHERE firma_id=p_firma_id AND iplik_id=sid ORDER BY created_at DESC LIMIT 1);
 RETURN r;
END $$;

CREATE FUNCTION public.iplik_lokasyonlu_siparis_teslimat_kaydet(p_firma_id uuid,p_siparis_id uuid,p_miktar numeric,p_lot_no text,p_kalite_durumu text,p_teslimat_tarihi date,p_aciklama text,p_lokasyon_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ DECLARE r jsonb; sid uuid; BEGIN
 IF NOT public.iplik_firma_uyesi(p_firma_id) THEN RAISE EXCEPTION 'Firma erisim yetkisi yok'; END IF;
 IF p_lokasyon_id IS NULL THEN RAISE EXCEPTION 'Lokasyon zorunludur'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.iplik_lokasyonlari WHERE id=p_lokasyon_id AND firma_id=p_firma_id AND aktif=true) THEN RAISE EXCEPTION 'Lokasyon aktif degil veya firmaya ait degil'; END IF;
 r:=public.iplik_siparis_teslimat_kaydet(p_firma_id,p_siparis_id,p_miktar,p_lot_no,p_kalite_durumu,p_teslimat_tarihi,p_aciklama); sid:=(r->>'stok_id')::uuid;
 INSERT INTO public.iplik_stok_lokasyonlari(firma_id,stok_id,lokasyon_id,miktar) VALUES(p_firma_id,sid,p_lokasyon_id,p_miktar)
 ON CONFLICT(firma_id,stok_id,lokasyon_id) DO UPDATE SET miktar=public.iplik_stok_lokasyonlari.miktar+EXCLUDED.miktar,updated_at=now();
 UPDATE public.iplik_hareketleri SET hedef_lokasyon_id=p_lokasyon_id WHERE id=(SELECT id FROM public.iplik_hareketleri WHERE firma_id=p_firma_id AND iplik_id=sid ORDER BY created_at DESC LIMIT 1); RETURN r; END $$;

CREATE FUNCTION public.iplik_sayim_oturumu_ac(p_firma_id uuid,p_aciklama text,p_lokasyon_ids uuid[]) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ DECLARE oid uuid; no text; lid uuid; BEGIN
 IF NOT public.iplik_firma_yoneticisi(p_firma_id) THEN RAISE EXCEPTION 'Sayim yonetici yetkisi gerektirir'; END IF;
 IF coalesce(array_length(p_lokasyon_ids,1),0)=0 THEN RAISE EXCEPTION 'En az bir lokasyon secin'; END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_lokasyon_ids) x WHERE NOT EXISTS(SELECT 1 FROM public.iplik_lokasyonlari l WHERE l.id=x AND l.firma_id=p_firma_id AND l.aktif=true)) THEN RAISE EXCEPTION 'Gecersiz sayim lokasyonu'; END IF;
 IF EXISTS(SELECT 1 FROM public.iplik_sayim_oturum_lokasyonlari ol JOIN public.iplik_sayim_oturumlari o ON o.id=ol.sayim_id WHERE o.firma_id=p_firma_id AND o.durum='taslak' AND ol.lokasyon_id=ANY(p_lokasyon_ids)) THEN RAISE EXCEPTION 'Secilen lokasyonda acik sayim bulunuyor'; END IF;
 no:='SAY-'||to_char(now(),'YYYYMMDD-HH24MISS');
 INSERT INTO public.iplik_sayim_oturumlari(firma_id,sayim_no,aciklama,acan_user_id) VALUES(p_firma_id,no,nullif(p_aciklama,''),auth.uid()) RETURNING id INTO oid;
 FOREACH lid IN ARRAY p_lokasyon_ids LOOP INSERT INTO public.iplik_sayim_oturum_lokasyonlari(firma_id,sayim_id,lokasyon_id) VALUES(p_firma_id,oid,lid); END LOOP;
 INSERT INTO public.iplik_sayim_satirlari(firma_id,sayim_id,lokasyon_id,stok_id,beklenen_miktar)
 SELECT firma_id,oid,lokasyon_id,stok_id,miktar FROM public.iplik_stok_lokasyonlari WHERE firma_id=p_firma_id AND lokasyon_id=ANY(p_lokasyon_ids) AND miktar>0;
 RETURN oid; END $$;

CREATE FUNCTION public.iplik_sayim_satiri_kaydet(p_firma_id uuid,p_sayim_id uuid,p_lokasyon_id uuid,p_stok_id uuid,p_sayilan numeric) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ BEGIN
 IF NOT public.iplik_firma_yoneticisi(p_firma_id) THEN RAISE EXCEPTION 'Sayim yonetici yetkisi gerektirir'; END IF;
 IF p_sayilan<0 THEN RAISE EXCEPTION 'Sayilan miktar negatif olamaz'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.iplik_sayim_oturumlari WHERE id=p_sayim_id AND firma_id=p_firma_id AND durum='taslak') THEN RAISE EXCEPTION 'Acik sayim bulunamadi'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.iplik_sayim_oturum_lokasyonlari WHERE sayim_id=p_sayim_id AND lokasyon_id=p_lokasyon_id AND firma_id=p_firma_id) THEN RAISE EXCEPTION 'Lokasyon sayim kapsaminda degil'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.iplik_stoklari WHERE id=p_stok_id AND firma_id=p_firma_id) THEN RAISE EXCEPTION 'Stok firmaya ait degil'; END IF;
 INSERT INTO public.iplik_sayim_satirlari(firma_id,sayim_id,lokasyon_id,stok_id,beklenen_miktar,sayilan_miktar,sayan_user_id,sayim_tarihi)
 VALUES(p_firma_id,p_sayim_id,p_lokasyon_id,p_stok_id,0,p_sayilan,auth.uid(),now())
 ON CONFLICT(sayim_id,lokasyon_id,stok_id) DO UPDATE SET sayilan_miktar=EXCLUDED.sayilan_miktar,sayan_user_id=auth.uid(),sayim_tarihi=now(),updated_at=now(); END $$;

CREATE FUNCTION public.iplik_sayim_oturumu_kapat(p_firma_id uuid,p_sayim_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ DECLARE rowx record; yeni numeric; rez numeric; BEGIN
 IF NOT public.iplik_firma_yoneticisi(p_firma_id) THEN RAISE EXCEPTION 'Sayim yonetici yetkisi gerektirir'; END IF;
 PERFORM 1 FROM public.iplik_sayim_oturumlari WHERE id=p_sayim_id AND firma_id=p_firma_id AND durum='taslak' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Acik sayim bulunamadi'; END IF;
 IF EXISTS(SELECT 1 FROM public.iplik_sayim_satirlari WHERE sayim_id=p_sayim_id AND sayilan_miktar IS NULL) THEN RAISE EXCEPTION 'Tum satirlar sayilmalidir'; END IF;
 FOR rowx IN SELECT DISTINCT stok_id FROM public.iplik_sayim_satirlari WHERE sayim_id=p_sayim_id LOOP
  SELECT
    coalesce((SELECT sum(sl.miktar) FROM public.iplik_stok_lokasyonlari sl
      WHERE sl.firma_id=p_firma_id AND sl.stok_id=rowx.stok_id
        AND NOT EXISTS(SELECT 1 FROM public.iplik_sayim_satirlari ss
          WHERE ss.sayim_id=p_sayim_id AND ss.stok_id=sl.stok_id AND ss.lokasyon_id=sl.lokasyon_id)),0)
    + coalesce((SELECT sum(ss.sayilan_miktar) FROM public.iplik_sayim_satirlari ss
      WHERE ss.sayim_id=p_sayim_id AND ss.stok_id=rowx.stok_id),0)
  INTO yeni;
  SELECT coalesce(sum(tahsis_miktari),0) INTO rez FROM public.iplik_stok_model_tahsisleri WHERE firma_id=p_firma_id AND stok_id=rowx.stok_id;
  IF yeni<rez THEN RAISE EXCEPTION 'Sayim sonucu model rezervasyonunun altinda'; END IF;
 END LOOP;
 FOR rowx IN SELECT * FROM public.iplik_sayim_satirlari WHERE sayim_id=p_sayim_id LOOP
  INSERT INTO public.iplik_stok_lokasyonlari(firma_id,stok_id,lokasyon_id,miktar) VALUES(p_firma_id,rowx.stok_id,rowx.lokasyon_id,rowx.sayilan_miktar)
  ON CONFLICT(firma_id,stok_id,lokasyon_id) DO UPDATE SET miktar=EXCLUDED.miktar,updated_at=now();
  IF rowx.sayilan_miktar<>rowx.beklenen_miktar THEN INSERT INTO public.iplik_hareketleri(iplik_id,hareket_tipi,miktar,aciklama,firma_id,kaynak_lokasyon_id,hedef_lokasyon_id,sayim_oturum_id,created_at,updated_at)
   VALUES(rowx.stok_id,'sayim',abs(rowx.sayilan_miktar-rowx.beklenen_miktar),'Lokasyon sayim farki: '||(rowx.sayilan_miktar-rowx.beklenen_miktar)::text,p_firma_id,rowx.lokasyon_id,rowx.lokasyon_id,p_sayim_id,now(),now()); END IF;
 END LOOP;
 UPDATE public.iplik_stoklari s SET miktar=x.toplam,updated_at=now(),toplam_deger=CASE WHEN s.birim_fiyat IS NULL THEN NULL ELSE x.toplam*s.birim_fiyat END
 FROM(SELECT stok_id,sum(miktar) toplam FROM public.iplik_stok_lokasyonlari WHERE firma_id=p_firma_id GROUP BY stok_id)x WHERE s.id=x.stok_id AND s.firma_id=p_firma_id;
 UPDATE public.iplik_sayim_oturumlari SET durum='tamamlandi',kapatan_user_id=auth.uid(),kapanis_tarihi=now(),updated_at=now() WHERE id=p_sayim_id AND firma_id=p_firma_id; END $$;

CREATE FUNCTION public.iplik_sayim_oturumu_iptal(p_firma_id uuid,p_sayim_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ BEGIN
 IF NOT public.iplik_firma_yoneticisi(p_firma_id) THEN RAISE EXCEPTION 'Sayim yonetici yetkisi gerektirir'; END IF;
 UPDATE public.iplik_sayim_oturumlari SET durum='iptal',kapatan_user_id=auth.uid(),kapanis_tarihi=now(),updated_at=now() WHERE id=p_sayim_id AND firma_id=p_firma_id AND durum='taslak';
 IF NOT FOUND THEN RAISE EXCEPTION 'Acik sayim bulunamadi'; END IF; END $$;

GRANT EXECUTE ON FUNCTION public.iplik_lokasyonlu_stok_hareket_kaydet(uuid,uuid,jsonb,text,numeric,text,uuid,uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iplik_lokasyonlu_siparis_teslimat_kaydet(uuid,uuid,numeric,text,text,date,text,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iplik_sayim_oturumu_ac(uuid,text,uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iplik_sayim_satiri_kaydet(uuid,uuid,uuid,uuid,numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iplik_sayim_oturumu_kapat(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iplik_sayim_oturumu_iptal(uuid,uuid) TO authenticated;
