-- Üretim aşamaları atama tabloları (UUID destekli)
-- Bu tablolar model atamalarını takip eder

-- Dokuma atamaları
CREATE TABLE IF NOT EXISTS public.dokuma_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Her model için sadece bir aktif atama
    UNIQUE(model_id)
);

-- Konfeksiyon atamaları
CREATE TABLE IF NOT EXISTS public.konfeksiyon_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- Yıkama atamaları
CREATE TABLE IF NOT EXISTS public.yikama_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- Ütü atamaları
CREATE TABLE IF NOT EXISTS public.utu_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- İlik Düğme atamaları
CREATE TABLE IF NOT EXISTS public.ilik_dugme_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- Kalite Kontrol atamaları
CREATE TABLE IF NOT EXISTS public.kalite_kontrol_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- Paketleme atamaları
CREATE TABLE IF NOT EXISTS public.paketleme_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'baslandi', 'tamamlandi', 'iptal')),
    notlar TEXT,
    baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id)
);

-- Row Level Security etkinleştir
ALTER TABLE public.dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yikama_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.utu_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paketleme_atamalari ENABLE ROW LEVEL SECURITY;

-- Politikalar (geçici olarak herkese tam erişim)
CREATE POLICY "Herkes atama verilerini görebilir" ON public.dokuma_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.konfeksiyon_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.yikama_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.utu_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.ilik_dugme_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.kalite_kontrol_atamalari FOR ALL USING (true);
CREATE POLICY "Herkes atama verilerini görebilir" ON public.paketleme_atamalari FOR ALL USING (true);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_model_id ON public.dokuma_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_kullanici_id ON public.dokuma_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_model_id ON public.konfeksiyon_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_kullanici_id ON public.konfeksiyon_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_model_id ON public.yikama_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_kullanici_id ON public.yikama_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_model_id ON public.utu_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_kullanici_id ON public.utu_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_model_id ON public.ilik_dugme_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_kullanici_id ON public.ilik_dugme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_model_id ON public.kalite_kontrol_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_kullanici_id ON public.kalite_kontrol_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_model_id ON public.paketleme_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_kullanici_id ON public.paketleme_atamalari(atanan_kullanici_id);