-- Aktif firma secimi RPC'si.
-- Uygulama TenantManager.firmaSecimi() icinde public.set_active_firma(p_firma_id)
-- fonksiyonunu cagiriyor. Bazi veritabanlarinda get_active_firma_id mevcutken
-- set_active_firma eksik kaldigi icin normal kullanici firma baglami secemiyor.

CREATE OR REPLACE FUNCTION public.has_firma_access(p_firma_id UUID)
RETURNS BOOLEAN AS $$
    SELECT
        p_firma_id IS NOT NULL
        AND (
            EXISTS (
                SELECT 1
                FROM public.user_roles ur
                WHERE ur.user_id = auth.uid()
                  AND ur.role = 'admin'
                  AND ur.aktif = true
            )
            OR EXISTS (
                SELECT 1
                FROM public.firma_kullanicilari fk
                WHERE fk.firma_id = p_firma_id
                  AND fk.user_id = auth.uid()
                  AND fk.aktif = true
            )
        );
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_active_firma_id()
RETURNS UUID AS $$
    SELECT kaf.firma_id
    FROM public.kullanici_aktif_firma kaf
    WHERE kaf.user_id = auth.uid()
      AND public.has_firma_access(kaf.firma_id)
    ORDER BY kaf.son_giris DESC NULLS LAST
    LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

DROP FUNCTION IF EXISTS public.set_active_firma(UUID);

CREATE OR REPLACE FUNCTION public.set_active_firma(p_firma_id UUID)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Oturum acik degil';
    END IF;

    IF p_firma_id IS NULL THEN
        RAISE EXCEPTION 'Firma ID zorunlu';
    END IF;

    IF NOT public.has_firma_access(p_firma_id) THEN
        RAISE EXCEPTION 'Bu firmaya erisiminiz yok: %', p_firma_id;
    END IF;

    INSERT INTO public.kullanici_aktif_firma (user_id, firma_id, son_giris)
    VALUES (v_user_id, p_firma_id, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        firma_id = EXCLUDED.firma_id,
        son_giris = NOW();

    RETURN p_firma_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.has_firma_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_firma_access(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_active_firma_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_firma_id() TO authenticated;

REVOKE ALL ON FUNCTION public.set_active_firma(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_active_firma(UUID) TO authenticated;
