-- URETIM_KAYITLARI TABLOSU KOLON KONTROLÜ VE DÜZELTME
-- Bu SQL'i çalıştırıp hangi kolonların olduğunu görelim

-- 1. Mevcut kolonları listele
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'uretim_kayitlari' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Örneklem veri de görelim (ilk 3 kayıt)
SELECT * FROM public.uretim_kayitlari LIMIT 3;

-- 3. Eğer musteri_adi kolonu yoksa ve gerekiyorsa ekleyelim
-- ALTER TABLE public.uretim_kayitlari ADD COLUMN musteri_adi TEXT;

-- 4. Test insert (hangi kolonların çalıştığını görmek için)
INSERT INTO public.uretim_kayitlari (
  model_id,
  asama,
  durum,
  atama_durumu,
  talep_edilen_adet,
  created_at
) VALUES (
  'test-model-123',
  'dokuma',
  'firma_onay_bekliyor',
  'atandi',
  1,
  NOW()
) ON CONFLICT DO NOTHING;