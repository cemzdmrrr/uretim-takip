-- ============================================================
-- aksesuar_stok_hareketleri tablosuna tedarikci_id ekle
-- Supabase SQL editöründe çalıştırın.
-- ============================================================

ALTER TABLE public.aksesuar_stok_hareketleri
  ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER
    REFERENCES public.tedarikciler(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ash_tedarikci
  ON public.aksesuar_stok_hareketleri (tedarikci_id);
