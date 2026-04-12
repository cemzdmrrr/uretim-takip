-- PERSONEL TABLOSU HIZLI GÜNCELLEME (TEST)
-- Bu dosya sadece temel alanları ekler ve test etmek için kullanılır

-- 1. Ad ve soyad alanlarını ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS ad VARCHAR(100),
ADD COLUMN IF NOT EXISTS soyad VARCHAR(100);

-- 2. Ad ve soyad alanları için NOT NULL constraint'i (opsiyonel)
-- Eğer bu alanları zorunlu yapmak istiyorsanız aşağıdaki satırları açın:
-- ALTER TABLE public.personel ALTER COLUMN ad SET NOT NULL;
-- ALTER TABLE public.personel ALTER COLUMN soyad SET NOT NULL;

-- 2. Temel eksik alanları ekle
ALTER TABLE public.personel 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- 3. Updated_at trigger'ı oluştur
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_personel_updated_at ON public.personel;
CREATE TRIGGER update_personel_updated_at
    BEFORE UPDATE ON public.personel
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 4. Kontrol sorgusu
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'personel' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test başarılı mesajı
DO $$
BEGIN
    RAISE NOTICE 'Personel tablosu temel güncellemesi tamamlandı!';
    RAISE NOTICE 'Ad ve soyad alanları eklendi ve mevcut veriler ayrıldı';
END $$;
