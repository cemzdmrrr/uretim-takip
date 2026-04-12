-- PERSONEL SOFT DELETE (YUMUŞAK SİLME) KOLONU EKLEMESİ
-- Bu script personel tablosuna silme_tarihi kolonu ekler
-- Personel silindiğinde gerçekten silinmez, durum 'pasif' yapılır

-- Silme tarihi kolonu ekle
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS silme_tarihi TIMESTAMP WITH TIME ZONE;

-- Durum kolonu yoksa ekle (varsayılan 'aktif')
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'aktif';

-- Mevcut kayıtlarda durum boş ise 'aktif' yap
UPDATE public.personel 
SET durum = 'aktif' 
WHERE durum IS NULL;

-- Index ekle - performans için
CREATE INDEX IF NOT EXISTS idx_personel_durum ON personel(durum);

-- Kontrol sorgusu
SELECT 
    COUNT(*) as toplam_personel,
    COUNT(*) FILTER (WHERE durum = 'aktif' OR durum IS NULL) as aktif_personel,
    COUNT(*) FILTER (WHERE durum = 'pasif') as pasif_personel
FROM personel;

SELECT 'Soft delete kolonu başarıyla eklendi!' as durum;
