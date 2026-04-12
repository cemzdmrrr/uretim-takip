-- Test schema to verify table creation
-- This file contains just the essential tables to test the view creation

-- Müşteriler tablosu
CREATE TABLE IF NOT EXISTS public.musteriler (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    soyad TEXT,
    sirket TEXT,
    telefon TEXT NOT NULL,
    email TEXT,
    adres TEXT,
    il TEXT,
    ilce TEXT,
    posta_kodu TEXT,
    vergi_no TEXT,
    vergi_dairesi TEXT,
    musteri_tipi TEXT NOT NULL DEFAULT 'bireysel' CHECK (musteri_tipi IN ('bireysel', 'kurumsal')),
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif', 'askida')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Triko takip tablosu
CREATE TABLE IF NOT EXISTS public.triko_takip (
    id BIGSERIAL PRIMARY KEY,
    marka TEXT NOT NULL,
    item_no TEXT NOT NULL,
    renk TEXT,
    urun_cinsi TEXT,
    iplik_cinsi TEXT,
    uretici TEXT,
    adet INTEGER DEFAULT 0,
    yuklenen_adet INTEGER DEFAULT 0,
    bedenler JSONB,
    termin TIMESTAMP WITH TIME ZONE,
    tamamlandi BOOLEAN DEFAULT false,
    musteri_id BIGINT REFERENCES public.musteriler(id),
    siparis_tarihi TIMESTAMP WITH TIME ZONE,
    siparis_notu TEXT,
    toplam_maliyet DECIMAL(15,2),
    kur TEXT DEFAULT 'TRY',
    
    -- Üretim aşamaları
    iplik_geldi BOOLEAN DEFAULT false,
    iplik_tarihi TIMESTAMP WITH TIME ZONE,
    kase_onayi BOOLEAN DEFAULT false,
    orgu_firma JSONB,
    konfeksiyon_firma JSONB,
    utu_firma JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Test view creation
CREATE OR REPLACE VIEW public.musteri_siparis_ozet AS
SELECT 
    m.id,
    m.ad,
    m.soyad,
    m.sirket,
    m.musteri_tipi,
    COUNT(t.id) as toplam_siparis,
    SUM(CASE WHEN t.tamamlandi = true THEN 1 ELSE 0 END) as tamamlanan_siparis,
    SUM(t.adet) as toplam_adet,
    SUM(t.yuklenen_adet) as toplam_yuklenen_adet,
    SUM(t.toplam_maliyet) as toplam_maliyet
FROM public.musteriler m
LEFT JOIN public.triko_takip t ON m.id = t.musteri_id
GROUP BY m.id, m.ad, m.soyad, m.sirket, m.musteri_tipi;

-- Test data
INSERT INTO public.musteriler (ad, soyad, sirket, telefon, email, musteri_tipi) VALUES
('Ahmet', 'Yılmaz', 'ABC Tekstil', '+90 212 555 0101', 'ahmet@abctekstil.com', 'kurumsal'),
('Fatma', 'Kara', NULL, '+90 216 555 0102', 'fatma@example.com', 'bireysel');

INSERT INTO public.triko_takip (marka, item_no, renk, adet, musteri_id, toplam_maliyet, tamamlandi) VALUES
('Nike', 'T001', 'Mavi', 100, 1, 5000.00, false),
('Adidas', 'T002', 'Kırmızı', 50, 2, 2500.00, true);
