-- ============================================================
-- aksesuar_stok_hareketleri tablosuna firma_id ekle
-- Supabase SQL editöründe çalıştırın.
-- ============================================================

-- 1. Kolonu ekle
ALTER TABLE public.aksesuar_stok_hareketleri
  ADD COLUMN IF NOT EXISTS firma_id UUID;

-- 2. Mevcut kayıtların firma_id'sini aksesuar_bedenler üzerinden doldur
UPDATE public.aksesuar_stok_hareketleri ash
SET firma_id = ab.firma_id
FROM public.aksesuar_bedenler ab
WHERE ash.aksesuar_beden_id = ab.id
  AND ash.firma_id IS NULL;

-- 3. İndeks
CREATE INDEX IF NOT EXISTS idx_ash_firma_id
  ON public.aksesuar_stok_hareketleri (firma_id);

-- 4. RLS
ALTER TABLE public.aksesuar_stok_hareketleri ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ash_firma_select" ON public.aksesuar_stok_hareketleri;
DROP POLICY IF EXISTS "ash_firma_insert" ON public.aksesuar_stok_hareketleri;

CREATE POLICY "ash_firma_select"
  ON public.aksesuar_stok_hareketleri FOR SELECT
  USING (firma_id = public.auth_kullanici_firma_id());

CREATE POLICY "ash_firma_insert"
  ON public.aksesuar_stok_hareketleri FOR INSERT
  WITH CHECK (firma_id = public.auth_kullanici_firma_id());
