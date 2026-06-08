-- Model detay fiyatlandirma ve maliyet/karlilik sekmeleri ayni maliyet
-- tabanini kullanmalidir. Aksesuarlar sekmesinden turetilen model aksesuar
-- satirlari fiyatlandirma toplaminda olmadigi icin aktif maliyet planindan
-- temizlenir.

DO $$
DECLARE
    v_model_id uuid;
BEGIN
    FOR v_model_id IN
        SELECT DISTINCT model_id
        FROM public.model_maliyet_kalemleri
        WHERE kalem_tipi = 'aksesuar'
          AND coalesce(kaynak, 'model') = 'model'
    LOOP
        DELETE FROM public.model_maliyet_kalemleri
        WHERE model_id = v_model_id
          AND kalem_tipi = 'aksesuar'
          AND coalesce(kaynak, 'model') = 'model';

        PERFORM public.model_karlilik_ozeti_yenile(v_model_id);
    END LOOP;
END $$;

