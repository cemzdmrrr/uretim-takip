    -- Aksesuar ve model_aksesuar tablolarını oluşturmak için SQL

    -- Önce mevcut aksesuarlar tablosunu kontrol et
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'aksesuarlar'
    );

    -- model_aksesuar tablosunu kontrol et  
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'model_aksesuar'
    );

    -- Eğer aksesuarlar tablosu yoksa oluştur (mevcut şemaya uygun)
    CREATE TABLE IF NOT EXISTS public.aksesuarlar (
        id SERIAL PRIMARY KEY,
        aksesuar_adi VARCHAR(255) NOT NULL,
        aksesuar_kodu VARCHAR(100) UNIQUE,
        birim VARCHAR(20) DEFAULT 'adet',
        stok_miktari INTEGER DEFAULT 0,
        birim_fiyat DECIMAL(15,2) DEFAULT 0,
        aciklama TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- model_aksesuar tablosunu oluştur (çoka çok ilişki için)
    CREATE TABLE IF NOT EXISTS public.model_aksesuar (
        id SERIAL PRIMARY KEY,
        model_id INTEGER NOT NULL REFERENCES public.modeller(id) ON DELETE CASCADE,
        aksesuar_id INTEGER NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
        miktar INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(model_id, aksesuar_id)
    );

    -- RLS'yi etkinleştir
    ALTER TABLE public.aksesuarlar ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.model_aksesuar ENABLE ROW LEVEL SECURITY;

    -- Gerekli politikaları oluştur
    CREATE POLICY "Herkes aksesuar okuyabilir" ON public.aksesuarlar FOR SELECT USING (true);
    CREATE POLICY "Herkes aksesuar ekleyebilir" ON public.aksesuarlar FOR INSERT WITH CHECK (true);
    CREATE POLICY "Herkes aksesuar güncelleyebilir" ON public.aksesuarlar FOR UPDATE USING (true);
    CREATE POLICY "Herkes aksesuar silebilir" ON public.aksesuarlar FOR DELETE USING (true);

    CREATE POLICY "Herkes model_aksesuar okuyabilir" ON public.model_aksesuar FOR SELECT USING (true);
    CREATE POLICY "Herkes model_aksesuar ekleyebilir" ON public.model_aksesuar FOR INSERT WITH CHECK (true);
    CREATE POLICY "Herkes model_aksesuar güncelleyebilir" ON public.model_aksesuar FOR UPDATE USING (true);
    CREATE POLICY "Herkes model_aksesuar silebilir" ON public.model_aksesuar FOR DELETE USING (true);

-- Test için birkaç aksesuar ekle (mevcut tablo yapısına göre)
-- Migration dosyasında aksesuar_adi var ama Supabase'de farklı olabilir
-- En yaygın alternatifler: ad, name, isim

INSERT INTO public.aksesuarlar (ad, kategori, miktar, birim, birim_fiyat) 
VALUES 
    ('Plastik Düğme 12mm', 'Düğme', 1000, 'adet', 0.50),
    ('Metal Fermuar 20cm', 'Fermuar', 500, 'adet', 2.50),
    ('Elastik Bant 1cm', 'Elastik', 200, 'metre', 1.25);

-- Eğer aksesuar_kodu kolonu yoksa ekle
ALTER TABLE public.aksesuarlar ADD COLUMN IF NOT EXISTS aksesuar_kodu VARCHAR(100) UNIQUE;

-- Eksik olan kolonları ekle
ALTER TABLE public.aksesuarlar ADD COLUMN IF NOT EXISTS kategori VARCHAR(100);
ALTER TABLE public.aksesuarlar ADD COLUMN IF NOT EXISTS resim_url TEXT;    -- Tablo bilgilerini göster
    SELECT 'Aksesuar tabloları başarıyla oluşturuldu!' as mesaj;
