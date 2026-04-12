-- TRIKO_TAKIP TABLOSU KOLON KONTROLÜ
-- Bu SQL'i çalıştırıp hangi kolonların olduğunu görelim

SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'triko_takip' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Örneklem veri de görelim (ilk 3 kayıt)
SELECT * FROM public.triko_takip LIMIT 3;