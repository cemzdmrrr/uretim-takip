-- ============================================================
-- DEBUG: Aksesuar kullanim tablosu durumunu kontrol et
-- Supabase SQL editöründe çalıştırın
-- ============================================================

-- 1. Tablonun kolon yapısını gör
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'aksesuar_kullanim'
ORDER BY ordinal_position;

-- 2. Tüm kayıtları gör (RLS bypass)
SELECT id, firma_id, aksesuar_id, islem_tipi, miktar, created_at
FROM public.aksesuar_kullanim
ORDER BY created_at DESC
LIMIT 20;

-- 3. firmalar tablosundaki firma ID'lerini gör
SELECT id, ad FROM public.firmalar LIMIT 10;

-- 4. Kayıttaki firma_id ile firmalar tablosunu karşılaştır
SELECT
  ak.id,
  ak.firma_id AS kullanim_firma_id,
  f.id AS firmalar_id,
  ak.firma_id = f.id AS eslesme_var
FROM public.aksesuar_kullanim ak
CROSS JOIN public.firmalar f
LIMIT 10;
