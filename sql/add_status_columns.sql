-- triko_takip tablosuna durum kolonları ekleme
ALTER TABLE public.triko_takip 
ADD COLUMN IF NOT EXISTS dokuma_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS konfeksiyon_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS yikama_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS utu_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS ilik_dugme_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS kalite_kontrol_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS paketleme_durumu TEXT DEFAULT 'beklemede',
ADD COLUMN IF NOT EXISTS nakis_durumu TEXT DEFAULT 'beklemede';

-- Durum değerlerini kontrol et
ALTER TABLE public.triko_takip 
ADD CONSTRAINT check_dokuma_durumu CHECK (dokuma_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_konfeksiyon_durumu CHECK (konfeksiyon_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_yikama_durumu CHECK (yikama_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_utu_durumu CHECK (utu_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_ilik_dugme_durumu CHECK (ilik_dugme_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_kalite_kontrol_durumu CHECK (kalite_kontrol_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_paketleme_durumu CHECK (paketleme_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi')),
ADD CONSTRAINT check_nakis_durumu CHECK (nakis_durumu IN ('beklemede', 'atandi', 'baslandi', 'tamamlandi'));