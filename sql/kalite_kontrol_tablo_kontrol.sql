-- Kalite kontrol atamaları tablosunu kontrol et ve düzelt

-- 1. Tablonun varlığını kontrol et
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public'
   AND table_name = 'kalite_kontrol_atamalari'
) as tablo_var;

-- 2. Tüm kalite kontrol atamalarını listele
SELECT 
    kka.id,
    kka.model_id,
    kka.durum,
    kka.onceki_asama,
    kka.kontrol_edilecek_adet,
    kka.atama_tarihi,
    t.marka,
    t.item_no
FROM kalite_kontrol_atamalari kka
LEFT JOIN triko_takip t ON t.id = kka.model_id
ORDER BY kka.created_at DESC;

-- 3. Eğer tablo yoksa oluştur
CREATE TABLE IF NOT EXISTS public.kalite_kontrol_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    durum TEXT DEFAULT 'beklemede',
    onceki_asama TEXT,
    kontrol_edilecek_adet INTEGER,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kontrol_tarihi TIMESTAMP WITH TIME ZONE,
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    notlar TEXT,
    planlanan_bitis_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. RLS'yi devre dışı bırak (geliştirme için)
ALTER TABLE public.kalite_kontrol_atamalari DISABLE ROW LEVEL SECURITY;

-- 5. Herkese okuma/yazma izni ver
GRANT ALL ON public.kalite_kontrol_atamalari TO authenticated;
GRANT ALL ON public.kalite_kontrol_atamalari TO anon;
GRANT USAGE, SELECT ON SEQUENCE kalite_kontrol_atamalari_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE kalite_kontrol_atamalari_id_seq TO anon;

-- 6. Test verisi ekle (isteğe bağlı - silmek için yorum satırı yapın)
-- INSERT INTO kalite_kontrol_atamalari (model_id, durum, onceki_asama, kontrol_edilecek_adet)
-- SELECT id, 'beklemede', 'Dokuma', 100 FROM triko_takip LIMIT 1;
