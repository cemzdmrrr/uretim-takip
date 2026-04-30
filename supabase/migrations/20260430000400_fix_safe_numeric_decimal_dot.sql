-- Hotfix: keep decimal dots when numeric JSON values are converted to text.
-- Example: 479.99 must stay 479.99, not become 47999.

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

-- Refresh profitability summaries after fixing numeric parsing.
DO $$
DECLARE
    v_model_id uuid;
BEGIN
    FOR v_model_id IN
        SELECT DISTINCT model_id
        FROM public.model_karlilik_ozetleri
    LOOP
        PERFORM public.model_karlilik_ozeti_yenile(v_model_id);
    END LOOP;
END;
$$;
