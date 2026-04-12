-- ================================================================================================
-- MUSTERI YONETIMI MODULU - SUPABASE SEMASI (GUNCEL)
-- ================================================================================================
-- Bu script mevcut sisteme musteri yonetimi modulu ekler
-- MEVCUT SISTEMI BOZMADAN yeni tablolar olusturur
-- Flutter MusteriModel ile uyumlu sema
-- ================================================================================================

-- Musteri kartlari tablosu
CREATE TABLE IF NOT EXISTS musteriler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100),
    sirket VARCHAR(255),
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    adres TEXT,
    il VARCHAR(50),
    ilce VARCHAR(50),
    posta_kodu VARCHAR(10),
    vergi_no VARCHAR(20),
    vergi_dairesi VARCHAR(100),
    musteri_tipi VARCHAR(20) DEFAULT 'bireysel' CHECK (musteri_tipi IN ('bireysel', 'kurumsal')),
    durum VARCHAR(20) DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif', 'askida')),
    notlar TEXT,
    kredi_limiti DECIMAL(15,2),
    bakiye DECIMAL(15,2) DEFAULT 0,
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Musteri iletisim gecmisi tablosu
CREATE TABLE IF NOT EXISTS musteri_iletisim (
    id SERIAL PRIMARY KEY,
    musteri_id INTEGER REFERENCES musteriler(id) ON DELETE CASCADE,
    iletisim_turu VARCHAR(20) NOT NULL CHECK (iletisim_turu IN ('telefon', 'email', 'ziyaret', 'toplanti', 'diger')),
    konu VARCHAR(255),
    detay TEXT,
    iletisim_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Musteri adres tablosu (coklu adres destegi icin)
CREATE TABLE IF NOT EXISTS musteri_adresler (
    id SERIAL PRIMARY KEY,
    musteri_id INTEGER REFERENCES musteriler(id) ON DELETE CASCADE,
    adres_turu VARCHAR(20) DEFAULT 'merkez' CHECK (adres_turu IN ('merkez', 'teslimat', 'fatura', 'diger')),
    adres TEXT,
    il VARCHAR(50),
    ilce VARCHAR(50),
    posta_kodu VARCHAR(10),
    varsayilan BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik guncelleme icin trigger
CREATE OR REPLACE FUNCTION update_musteri_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS musteriler_updated_at_trigger ON musteriler;
CREATE TRIGGER musteriler_updated_at_trigger
    BEFORE UPDATE ON musteriler
    FOR EACH ROW
    EXECUTE FUNCTION update_musteri_updated_at();

-- RLS (Row Level Security) politikalari
ALTER TABLE musteriler ENABLE ROW LEVEL SECURITY;
ALTER TABLE musteri_iletisim ENABLE ROW LEVEL SECURITY;
ALTER TABLE musteri_adresler ENABLE ROW LEVEL SECURITY;

-- Tum kullanicilar okuyabilir
CREATE POLICY "Kullanicilar musterileri gorebilir" ON musteriler
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar musteri iletisimi gorebilir" ON musteri_iletisim
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar musteri adreslerini gorebilir" ON musteri_adresler
    FOR SELECT USING (true);

-- Sadece admin ve user rolu ekleyebilir/guncelleyebilir
CREATE POLICY "Admin ve user musteri ekleyebilir" ON musteriler
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin ve user musteri guncelleyebilir" ON musteriler
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin musteri silebilir" ON musteriler
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Iletisim gecmisi icin politikalar
CREATE POLICY "Herkes musteri iletisimi ekleyebilir" ON musteri_iletisim
    FOR INSERT WITH CHECK (true);

-- Adres icin politikalar  
CREATE POLICY "Admin ve user musteri adresi ekleyebilir" ON musteri_adresler
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

-- Indeksler (performans icin)
CREATE INDEX IF NOT EXISTS idx_musteriler_ad ON musteriler(ad);
CREATE INDEX IF NOT EXISTS idx_musteriler_sirket ON musteriler(sirket);
CREATE INDEX IF NOT EXISTS idx_musteriler_telefon ON musteriler(telefon);
CREATE INDEX IF NOT EXISTS idx_musteriler_email ON musteriler(email);
CREATE INDEX IF NOT EXISTS idx_musteriler_vergi_no ON musteriler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_musteriler_durum ON musteriler(durum);
CREATE INDEX IF NOT EXISTS idx_musteriler_musteri_tipi ON musteriler(musteri_tipi);
CREATE INDEX IF NOT EXISTS idx_musteri_iletisim_musteri_id ON musteri_iletisim(musteri_id);
CREATE INDEX IF NOT EXISTS idx_musteri_adresler_musteri_id ON musteri_adresler(musteri_id);

-- Unique constraints (tekrar eden kayitlari onlemek icin)
-- PostgreSQL'de IF NOT EXISTS constraint icin ozel yaklasim
DO $$
BEGIN
    -- Telefon unique constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_telefon' AND table_name = 'musteriler'
    ) THEN
        ALTER TABLE musteriler ADD CONSTRAINT unique_telefon UNIQUE (telefon);
    END IF;
    
    -- Email unique constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_email' AND table_name = 'musteriler'
    ) THEN
        ALTER TABLE musteriler ADD CONSTRAINT unique_email UNIQUE (email);
    END IF;
    
    -- Vergi no unique constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_vergi_no' AND table_name = 'musteriler'
    ) THEN
        ALTER TABLE musteriler ADD CONSTRAINT unique_vergi_no UNIQUE (vergi_no);
    END IF;
END $$;

-- Ornek veri (test icin)
INSERT INTO musteriler (
    ad, soyad, telefon, email, adres, il, ilce, 
    musteri_tipi, durum, notlar
) VALUES 
(
    'Ahmet', 'YILMAZ', '05321234567', 'ahmet.yilmaz@email.com', 
    'Ornek Mahallesi, Ornek Sokak No:1', 'Istanbul', 'Kadikoy',
    'bireysel', 'aktif', 'Duzenli musteri'
),
(
    'Fatma', 'KAYA', '05339876543', 'fatma.kaya@email.com',
    'Test Caddesi No:25', 'Istanbul', 'Beyoglu', 
    'bireysel', 'aktif', 'Hizli teslimat istiyor'
);

INSERT INTO musteriler (
    ad, sirket, telefon, email, adres, il, ilce, vergi_no, vergi_dairesi,
    musteri_tipi, durum, kredi_limiti, notlar
) VALUES 
(
    'Mehmet DEMIR', 'Ornek Tekstil Ltd. Sti.', '02165550001', 'info@ornektekstil.com', 
    'Sanayi Mahallesi, Fabrika Caddesi No:15', 'Istanbul', 'Umraniye',
    '1234567890', 'Umraniye VD', 'kurumsal', 'aktif', 50000.00,
    'Onemli kurumsal musteri, buyuk siparisler veriyor'
);

-- Basari mesaji
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'MUSTERI YONETIMI MODULU BASARIYLA KURULDU';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Olusturulan tablolar:';
    RAISE NOTICE '- musteriler (ana musteri kartlari)';
    RAISE NOTICE '- musteri_iletisim (iletisim gecmisi)';
    RAISE NOTICE '- musteri_adresler (coklu adres destegi)';
    RAISE NOTICE '';
    RAISE NOTICE 'Toplam musteri sayisi: %', (SELECT COUNT(*) FROM musteriler);
    RAISE NOTICE '========================================';
END $$;
