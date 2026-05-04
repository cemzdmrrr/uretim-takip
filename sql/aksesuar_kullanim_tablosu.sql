-- Aksesuar Kullanım / Sarf Kayıt Tablosu
-- Bu tablo aksesuar stoktan yapılan sarf işlemlerini kayıt altına alır.

CREATE TABLE IF NOT EXISTS public.aksesuar_kullanim (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id    TEXT NOT NULL,
    aksesuar_id TEXT NOT NULL,           -- aksesuarlar.id (UUID veya text)
    beden_id    TEXT,                    -- aksesuar_bedenler.id
    beden       TEXT,                    -- beden adı (S, M, L, 18mm vb.)
    musteri_id  TEXT,                    -- tedarikciler.id (hangi tedarikçiye/bölüme sarf)
    miktar      INTEGER NOT NULL DEFAULT 0,
    islem_tipi  TEXT NOT NULL DEFAULT 'sarf',  -- 'sarf' | 'iade' | 'fire'
    aciklama    TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- İndeksler
CREATE INDEX IF NOT EXISTS aksesuar_kullanim_firma_idx   ON public.aksesuar_kullanim (firma_id);
CREATE INDEX IF NOT EXISTS aksesuar_kullanim_aksesuar_idx ON public.aksesuar_kullanim (aksesuar_id);
CREATE INDEX IF NOT EXISTS aksesuar_kullanim_tarih_idx   ON public.aksesuar_kullanim (created_at);

-- RLS
ALTER TABLE public.aksesuar_kullanim ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "aksesuar_kullanim_firma_select" ON public.aksesuar_kullanim;
DROP POLICY IF EXISTS "aksesuar_kullanim_firma_insert" ON public.aksesuar_kullanim;
DROP POLICY IF EXISTS "aksesuar_kullanim_firma_update" ON public.aksesuar_kullanim;

CREATE POLICY "aksesuar_kullanim_firma_select"
    ON public.aksesuar_kullanim FOR SELECT
    USING (firma_id = (SELECT firma_id FROM public.firma_kullanicilari WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "aksesuar_kullanim_firma_insert"
    ON public.aksesuar_kullanim FOR INSERT
    WITH CHECK (firma_id = (SELECT firma_id FROM public.firma_kullanicilari WHERE user_id = auth.uid() LIMIT 1));

CREATE POLICY "aksesuar_kullanim_firma_update"
    ON public.aksesuar_kullanim FOR UPDATE
    USING (firma_id = (SELECT firma_id FROM public.firma_kullanicilari WHERE user_id = auth.uid() LIMIT 1));
