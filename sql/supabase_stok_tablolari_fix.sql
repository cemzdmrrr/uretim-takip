-- İplik ve aksesuar stok tabloları oluşturma
-- Bu dosyayı Supabase SQL editörde çalıştırın

-- İplik stokları tablosu
CREATE TABLE IF NOT EXISTS public.iplik_stoklari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ad TEXT NOT NULL,
    renk TEXT,
    lot_no TEXT,
    miktar DECIMAL(10,2) DEFAULT 0,
    birim TEXT DEFAULT 'kg',
    birim_fiyat DECIMAL(10,2),
    toplam_deger DECIMAL(15,2),
    tedarikci_id INTEGER REFERENCES public.tedarikciler(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- İplik hareketleri tablosu
CREATE TABLE IF NOT EXISTS public.iplik_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iplik_id UUID NOT NULL REFERENCES public.iplik_stoklari(id) ON DELETE CASCADE,
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer', 'sayim')),
    miktar DECIMAL(10,2) NOT NULL,
    kalan_miktar DECIMAL(10,2),
    aciklama TEXT,
    model_id UUID REFERENCES public.triko_takip(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Aksesuarlar tablosu
CREATE TABLE IF NOT EXISTS public.aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ad TEXT NOT NULL,
    kategori TEXT,
    beden TEXT,
    renk TEXT,
    miktar DECIMAL(10,2) DEFAULT 0,
    birim TEXT DEFAULT 'adet',
    birim_fiyat DECIMAL(10,2),
    toplam_deger DECIMAL(15,2),
    tedarikci_id INTEGER REFERENCES public.tedarikciler(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Aksesuar hareketleri tablosu
CREATE TABLE IF NOT EXISTS public.aksesuar_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer', 'sayim')),
    miktar DECIMAL(10,2) NOT NULL,
    kalan_miktar DECIMAL(10,2),
    aciklama TEXT,
    model_id UUID REFERENCES public.triko_takip(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS politikaları
ALTER TABLE public.iplik_stoklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aksesuarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aksesuar_hareketleri ENABLE ROW LEVEL SECURITY;

-- Okuma politikaları
CREATE POLICY "Herkes iplik stok verilerini okuyabilir" ON public.iplik_stoklari FOR SELECT USING (true);
CREATE POLICY "Herkes iplik hareket verilerini okuyabilir" ON public.iplik_hareketleri FOR SELECT USING (true);
CREATE POLICY "Herkes aksesuar stok verilerini okuyabilir" ON public.aksesuarlar FOR SELECT USING (true);
CREATE POLICY "Herkes aksesuar hareket verilerini okuyabilir" ON public.aksesuar_hareketleri FOR SELECT USING (true);

-- Yazma politikaları (authenticated users)
CREATE POLICY "Authenticated users can insert iplik stok" ON public.iplik_stoklari FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update iplik stok" ON public.iplik_stoklari FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete iplik stok" ON public.iplik_stoklari FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert iplik hareket" ON public.iplik_hareketleri FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update iplik hareket" ON public.iplik_hareketleri FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete iplik hareket" ON public.iplik_hareketleri FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert aksesuar stok" ON public.aksesuarlar FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update aksesuar stok" ON public.aksesuarlar FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete aksesuar stok" ON public.aksesuarlar FOR DELETE TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert aksesuar hareket" ON public.aksesuar_hareketleri FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update aksesuar hareket" ON public.aksesuar_hareketleri FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete aksesuar hareket" ON public.aksesuar_hareketleri FOR DELETE TO authenticated USING (true);

-- Test verisi ekleme (isteğe bağlı - mevcut tablo yapısına göre düzenleyin)
-- Önce mevcut aksesuarlar tablosunun yapısını kontrol edin:
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'aksesuarlar';

-- İplik stokları için test verisi
INSERT INTO public.iplik_stoklari (ad, renk, miktar, birim, birim_fiyat) 
VALUES 
    ('Cotton 30/1', 'Beyaz', 100.5, 'kg', 25.50),
    ('Polyester DTY', 'Lacivert', 75.0, 'kg', 18.75),
    ('Viskon 20/1', 'Kırmızı', 50.25, 'kg', 32.00)
ON CONFLICT DO NOTHING;

-- Aksesuarlar için test verisi - mevcut tablo yapısına göre düzenlenecek
-- Tablo yapısını kontrol ettikten sonra bu kısmı düzenleyin
/*
INSERT INTO public.aksesuarlar (ad, kategori, miktar, birim, birim_fiyat) 
VALUES 
    ('Düğme', 'Düğme', 1000, 'adet', 0.50),
    ('Fermuar', 'Fermuar', 250, 'adet', 2.75),
    ('Etiket', 'Etiket', 500, 'adet', 0.25)
ON CONFLICT DO NOTHING;
*/

-- Trigger fonksiyonları
CREATE OR REPLACE FUNCTION public.update_iplik_stok_toplam_deger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.miktar IS NOT NULL AND NEW.birim_fiyat IS NOT NULL THEN
        NEW.toplam_deger = NEW.miktar * NEW.birim_fiyat;
    END IF;
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.update_aksesuar_stok_toplam_deger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.miktar IS NOT NULL AND NEW.birim_fiyat IS NOT NULL THEN
        NEW.toplam_deger = NEW.miktar * NEW.birim_fiyat;
    END IF;
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggerları oluştur
DROP TRIGGER IF EXISTS trigger_update_iplik_stok_toplam_deger ON public.iplik_stoklari;
CREATE TRIGGER trigger_update_iplik_stok_toplam_deger
    BEFORE INSERT OR UPDATE ON public.iplik_stoklari
    FOR EACH ROW EXECUTE FUNCTION public.update_iplik_stok_toplam_deger();

DROP TRIGGER IF EXISTS trigger_update_aksesuar_stok_toplam_deger ON public.aksesuarlar;
CREATE TRIGGER trigger_update_aksesuar_stok_toplam_deger
    BEFORE INSERT OR UPDATE ON public.aksesuarlar
    FOR EACH ROW EXECUTE FUNCTION public.update_aksesuar_stok_toplam_deger();
