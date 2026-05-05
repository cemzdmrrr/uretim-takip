-- ============================================================
-- aksesuar_kullanim tablosuna model_id kolonu ekle
-- Supabase SQL editöründe çalıştırın.
-- ============================================================

ALTER TABLE public.aksesuar_kullanim
  ADD COLUMN IF NOT EXISTS model_id UUID
    REFERENCES public.triko_takip(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS aksesuar_kullanim_model_idx
  ON public.aksesuar_kullanim (model_id);
