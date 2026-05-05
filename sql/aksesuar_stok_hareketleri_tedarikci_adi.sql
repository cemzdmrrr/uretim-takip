-- ============================================================
-- aksesuar_stok_hareketleri tablosuna tedarikci_adi TEXT kolonu ekle
-- FK gerektirmez, tedarikçi adını direkt metin olarak saklar.
-- Supabase SQL editöründe çalıştırın.
-- ============================================================

ALTER TABLE public.aksesuar_stok_hareketleri
  ADD COLUMN IF NOT EXISTS tedarikci_adi TEXT;
