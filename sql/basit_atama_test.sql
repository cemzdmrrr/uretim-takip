-- BASIT ATAMA TESTI - NOT NULL KISTLAMALARIYLA
-- Bu SQL'i çalıştırarak hangi kolonların NOT NULL olduğunu görelim

-- 1. Tablo yapısını göster
\d public.uretim_kayitlari

-- 2. NOT NULL kısıtlamalarını kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'uretim_kayitlari' 
AND table_schema = 'public'
AND is_nullable = 'NO'  -- NOT NULL kolonları
ORDER BY ordinal_position;

-- 3. Güvenli insert dene
INSERT INTO public.uretim_kayitlari (
    model_id, 
    asama, 
    durum, 
    tamamlanan_adet, 
    uretilen_adet, 
    talep_edilen_adet
) VALUES (
    'test-123', 
    'dokuma', 
    'atandi', 
    0, 
    0, 
    1
) ON CONFLICT DO NOTHING;

-- 3. Tablodaki tüm kayıtları göster
SELECT * FROM public.uretim_kayitlari ORDER BY id DESC LIMIT 10;

-- 4. Eğer tablo yoksa oluştur (temel yapı)
CREATE TABLE IF NOT EXISTS public.uretim_kayitlari (
    id SERIAL PRIMARY KEY,
    model_id TEXT,
    asama TEXT,
    durum TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);