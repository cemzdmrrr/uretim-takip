-- TCKN Hatası Çözümü için Özel SQL Komutları
-- Bu komutları sırayla çalıştırın

-- 1. Önce mevcut indeksleri kontrol edin
SELECT indexname, tablename, indexdef 
FROM pg_indexes 
WHERE tablename = 'personel' AND indexname LIKE '%tckn%';

-- 2. Eğer eski bir tckn indeksi varsa silin
DROP INDEX IF EXISTS idx_personel_tckn;

-- 3. Personel tablosunun mevcut yapısını kontrol edin
\d public.personel;

-- 4. Eğer tckn kolonu yoksa ekleyin
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS tckn TEXT;

-- 5. UNIQUE constraint ekleyin (eğer yoksa)
ALTER TABLE public.personel ADD CONSTRAINT personel_tckn_unique UNIQUE (tckn);

-- 6. İndeksi yeniden oluşturun
CREATE INDEX IF NOT EXISTS idx_personel_tckn ON public.personel(tckn);

-- 7. Sonucu kontrol edin
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'personel' AND column_name = 'tckn';

-- 8. İndeksin oluştuğunu kontrol edin
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'personel' AND indexname = 'idx_personel_tckn';
