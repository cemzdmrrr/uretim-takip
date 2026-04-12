-- Aksesuar kullanım (sarf) kayıtları tablosu
CREATE TABLE IF NOT EXISTS public.aksesuar_kullanim (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
    beden_id UUID REFERENCES public.aksesuar_bedenler(id) ON DELETE SET NULL,
    beden TEXT,
    musteri_id TEXT,
    miktar INTEGER NOT NULL DEFAULT 1,
    islem_tipi TEXT NOT NULL DEFAULT 'sarf',
    aciklama TEXT,
    firma_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_aksesuar_kullanim_aksesuar_id ON public.aksesuar_kullanim(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_kullanim_firma_id ON public.aksesuar_kullanim(firma_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_kullanim_musteri_id ON public.aksesuar_kullanim(musteri_id);
CREATE INDEX IF NOT EXISTS idx_aksesuar_kullanim_created_at ON public.aksesuar_kullanim(created_at);
