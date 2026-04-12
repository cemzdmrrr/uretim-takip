-- Kalite kontrol atamalari tablosunu güncelle
-- atanan_kullanici_id sütununu nullable yap (otomatik atamalar için)

-- 1. Mevcut constraint'i kaldır (varsa)
ALTER TABLE public.kalite_kontrol_atamalari 
ALTER COLUMN atanan_kullanici_id DROP NOT NULL;

-- 2. onceki_asama sütunu ekle (yoksa)
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS onceki_asama TEXT;

-- 3. kontrol_edilecek_adet sütunu ekle (yoksa)
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS kontrol_edilecek_adet INTEGER;

-- 4. baslangic_tarihi sütunu ekle (yoksa)
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS baslangic_tarihi TIMESTAMP WITH TIME ZONE;

-- 5. tamamlanma_tarihi sütunu ekle (yoksa)
ALTER TABLE public.kalite_kontrol_atamalari 
ADD COLUMN IF NOT EXISTS tamamlanma_tarihi TIMESTAMP WITH TIME ZONE;

-- 6. CHECK constraint'i güncelle - daha fazla durum destekle
-- Önce mevcut constraint'i kaldır
ALTER TABLE public.kalite_kontrol_atamalari 
DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_durum_check;

-- Yeni constraint ekle
ALTER TABLE public.kalite_kontrol_atamalari 
ADD CONSTRAINT kalite_kontrol_atamalari_durum_check 
CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal', 'beklemede', 'kontrolde', 'onaylandi', 'reddedildi'));

-- 7. UNIQUE constraint'i kaldır (aynı model için birden fazla kontrol olabilir)
ALTER TABLE public.kalite_kontrol_atamalari 
DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_model_id_key;

-- 8. RLS'yi devre dışı bırak
ALTER TABLE public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;

-- 9. Yetkileri ver
GRANT ALL ON public.kalite_kontrol_atamalari TO authenticated;
GRANT ALL ON public.kalite_kontrol_atamalari TO anon;

-- =============================================
-- PAKETLEME ATAMALARI TABLOSU GÜNCELLEMELERİ
-- =============================================

-- Paketleme tablosunda atanan_kullanici_id nullable yap
ALTER TABLE public.paketleme_atamalari 
ALTER COLUMN atanan_kullanici_id DROP NOT NULL;

-- Paketleme tablosunda eksik sütunları ekle
ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS adet INTEGER;

ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS talep_edilen_adet INTEGER;

ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS tamamlanan_adet INTEGER DEFAULT 0;

ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS hedef_asama TEXT;

ALTER TABLE public.paketleme_atamalari 
ADD COLUMN IF NOT EXISTS tamamlanma_tarihi TIMESTAMP WITH TIME ZONE;

-- Paketleme CHECK constraint güncelle
ALTER TABLE public.paketleme_atamalari 
DROP CONSTRAINT IF EXISTS paketleme_atamalari_durum_check;

ALTER TABLE public.paketleme_atamalari 
ADD CONSTRAINT paketleme_atamalari_durum_check 
CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal', 'beklemede', 'uretimde', 'onaylandi'));

-- Paketleme UNIQUE constraint kaldır
ALTER TABLE public.paketleme_atamalari 
DROP CONSTRAINT IF EXISTS paketleme_atamalari_model_id_key;

-- RLS kapat
ALTER TABLE public.paketleme_atamalari DISABLE ROW LEVEL SECURITY;

-- Yetki ver
GRANT ALL ON public.paketleme_atamalari TO authenticated;
GRANT ALL ON public.paketleme_atamalari TO anon;

-- 10. Tablo yapısını kontrol et
SELECT 'kalite_kontrol_atamalari' as tablo, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'kalite_kontrol_atamalari'
ORDER BY ordinal_position;

SELECT 'paketleme_atamalari' as tablo, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'paketleme_atamalari'
ORDER BY ordinal_position;
