    -- ============================================================
    -- aksesuar_kullanim tablosunu UUID FK'larla yeniden oluştur
    -- Supabase SQL editöründe çalıştırın.
    -- NOT: Tabloda veri varsa önce yedek alın.
    -- ============================================================

    -- Yardımcı fonksiyon: mevcut kullanıcının firma_id'sini döndürür (RLS bypass)
    CREATE OR REPLACE FUNCTION public.auth_kullanici_firma_id()
    RETURNS UUID
    LANGUAGE sql
    SECURITY DEFINER
    STABLE
    AS $$
    SELECT firma_id
    FROM public.firma_kullanicilari
    WHERE user_id = auth.uid()
        AND aktif = true
    LIMIT 1;
    $$;

    DROP TABLE IF EXISTS public.aksesuar_kullanim;

    CREATE TABLE public.aksesuar_kullanim (
        id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
        firma_id    UUID        NOT NULL,
        aksesuar_id UUID        NOT NULL REFERENCES public.aksesuarlar(id)    ON DELETE CASCADE,
        beden_id    UUID                    REFERENCES public.aksesuar_bedenler(id) ON DELETE SET NULL,
        beden       TEXT,
        musteri_id  TEXT,                   -- tedarikciler.id (integer text olarak saklanır, tip uyumsuzluğu nedeniyle FK yok)
        model_id    UUID                    REFERENCES public.triko_takip(id)  ON DELETE SET NULL,
        miktar      INTEGER     NOT NULL DEFAULT 0,
        islem_tipi  TEXT        NOT NULL DEFAULT 'sarf',
        aciklama    TEXT,
        created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- İndeksler
    CREATE INDEX IF NOT EXISTS aksesuar_kullanim_firma_idx    ON public.aksesuar_kullanim (firma_id);
    CREATE INDEX IF NOT EXISTS aksesuar_kullanim_aksesuar_idx ON public.aksesuar_kullanim (aksesuar_id);
    CREATE INDEX IF NOT EXISTS aksesuar_kullanim_model_idx    ON public.aksesuar_kullanim (model_id);
    CREATE INDEX IF NOT EXISTS aksesuar_kullanim_tarih_idx    ON public.aksesuar_kullanim (created_at);

    -- RLS
    ALTER TABLE public.aksesuar_kullanim ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "aksesuar_kullanim_firma_select" ON public.aksesuar_kullanim;
    DROP POLICY IF EXISTS "aksesuar_kullanim_firma_insert" ON public.aksesuar_kullanim;
    DROP POLICY IF EXISTS "aksesuar_kullanim_firma_update" ON public.aksesuar_kullanim;

    CREATE POLICY "aksesuar_kullanim_firma_select"
        ON public.aksesuar_kullanim FOR SELECT
        USING (firma_id = public.auth_kullanici_firma_id());

    CREATE POLICY "aksesuar_kullanim_firma_insert"
        ON public.aksesuar_kullanim FOR INSERT
        WITH CHECK (firma_id = public.auth_kullanici_firma_id());

    CREATE POLICY "aksesuar_kullanim_firma_update"
        ON public.aksesuar_kullanim FOR UPDATE
        USING (firma_id = public.auth_kullanici_firma_id());
