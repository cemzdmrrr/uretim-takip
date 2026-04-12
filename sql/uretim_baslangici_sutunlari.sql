-- Üretim Başlangıcı için yeni sütunlar ekleme
-- Model Detay sayfasındaki yeni "Üretim Başlangıcı" sekmesi için gerekli alanlar

-- triko_takip tablosuna yeni sütunlar ekle
ALTER TABLE public.triko_takip 
ADD COLUMN IF NOT EXISTS iplik_gelis_tarihi TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS orguye_baslayabilir BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS first_fit_gonderildi TEXT CHECK (first_fit_gonderildi IN ('evet', 'hayir')),
ADD COLUMN IF NOT EXISTS first_fit_aciklama TEXT,
ADD COLUMN IF NOT EXISTS size_set_gonderildi TEXT CHECK (size_set_gonderildi IN ('evet', 'hayir')),
ADD COLUMN IF NOT EXISTS size_set_aciklama TEXT,
ADD COLUMN IF NOT EXISTS pps_numunesi_gonderildi TEXT CHECK (pps_numunesi_gonderildi IN ('evet', 'hayir')),
ADD COLUMN IF NOT EXISTS pps_numunesi_aciklama TEXT;

-- Yorum: Mevcut iplik_geldi sütunu zaten mevcut (BOOLEAN olarak)
-- Bu yüzden onu değiştirmiyoruz, sadece tarih sütunu ekliyoruz

-- Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_triko_takip_first_fit ON public.triko_takip(first_fit_gonderildi);
CREATE INDEX IF NOT EXISTS idx_triko_takip_size_set ON public.triko_takip(size_set_gonderildi);
CREATE INDEX IF NOT EXISTS idx_triko_takip_pps_numunesi ON public.triko_takip(pps_numunesi_gonderildi);

-- Test verisi (isteğe bağlı - mevcut kayıtlara default değerler atayabilirsiniz)
-- UPDATE public.triko_takip SET 
--     orguye_baslayabilir = false,
--     first_fit_gonderildi = NULL,
--     first_fit_aciklama = '',
--     size_set_gonderildi = NULL,
--     size_set_aciklama = '',
--     pps_numunesi_gonderildi = NULL,
--     pps_numunesi_aciklama = ''
-- WHERE first_fit_gonderildi IS NULL;

-- Tabloya yorum ekle
COMMENT ON COLUMN public.triko_takip.iplik_gelis_tarihi IS 'İplik geliş tarihi - iplik_geldi false olduğunda kullanılır';
COMMENT ON COLUMN public.triko_takip.orguye_baslayabilir IS 'Örgüye başlanıp başlanamayacağını belirtir';
COMMENT ON COLUMN public.triko_takip.first_fit_gonderildi IS 'First Fit numunesi gönderildi mi? (evet/hayir)';
COMMENT ON COLUMN public.triko_takip.first_fit_aciklama IS 'First Fit numunesi ile ilgili açıklama';
COMMENT ON COLUMN public.triko_takip.size_set_gonderildi IS 'Size Set gönderildi mi? (evet/hayir)';
COMMENT ON COLUMN public.triko_takip.size_set_aciklama IS 'Size Set ile ilgili açıklama';
COMMENT ON COLUMN public.triko_takip.pps_numunesi_gonderildi IS 'PPS numunesi gönderildi mi? (evet/hayir)';
COMMENT ON COLUMN public.triko_takip.pps_numunesi_aciklama IS 'PPS numunesi ile ilgili açıklama';

-- Migration tamamlandı
SELECT 'Üretim Başlangıcı sütunları başarıyla eklendi!' as status;
