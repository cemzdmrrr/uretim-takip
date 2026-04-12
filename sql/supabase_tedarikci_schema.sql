-- ================================================================================================
-- TEDARIKCI YONETIMI MODULU - SUPABASE SEMASI
-- ================================================================================================
-- Bu script mevcut sisteme tedarikci yonetimi modulu ekler
-- MEVCUT SISTEMI BOZMADAN yeni tablolar olusturur
-- Flutter TedarikciModel ile uyumlu sema
-- ================================================================================================

-- Tedarikci kartlari tablosu (Basitleştirilmiş)
CREATE TABLE IF NOT EXISTS tedarikciler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100),
    sirket VARCHAR(255),
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    tedarikci_tipi VARCHAR(30) DEFAULT 'Üretici' CHECK (tedarikci_tipi IN ('Üretici', 'İthalatçı', 'Distribütör', 'Bayi', 'Hizmet Sağlayıcı', 'Diğer')),
    faaliyet VARCHAR(30) CHECK (faaliyet IN ('Tekstil', 'İplik', 'Aksesuar', 'Makine', 'Kimyasal', 'Ambalaj', 'Lojistik', 'Diğer') OR faaliyet IS NULL),
    durum VARCHAR(20) DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif', 'beklemede')),
    vergi_no VARCHAR(20),
    tc_kimlik VARCHAR(11),
    iban_no VARCHAR(34),
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tedarikci iletisim gecmisi tablosu
CREATE TABLE IF NOT EXISTS tedarikci_iletisim (
    id SERIAL PRIMARY KEY,
    tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE CASCADE,
    iletisim_turu VARCHAR(20) NOT NULL CHECK (iletisim_turu IN ('telefon', 'email', 'ziyaret', 'toplanti', 'diger')),
    konu VARCHAR(255),
    detay TEXT,
    iletisim_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tedarikci adres tablosu (coklu adres destegi icin)
CREATE TABLE IF NOT EXISTS tedarikci_adresler (
    id SERIAL PRIMARY KEY,
    tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE CASCADE,
    adres_turu VARCHAR(20) DEFAULT 'merkez' CHECK (adres_turu IN ('merkez', 'teslimat', 'fatura', 'diger')),
    adres TEXT,
    il VARCHAR(50),
    ilce VARCHAR(50),
    posta_kodu VARCHAR(10),
    varsayilan BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tedarikci fiyat listeleri tablosu
CREATE TABLE IF NOT EXISTS tedarikci_fiyat_listeleri (
    id SERIAL PRIMARY KEY,
    tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE CASCADE,
    urun_kodu VARCHAR(100),
    urun_adi VARCHAR(255) NOT NULL,
    birim VARCHAR(20) DEFAULT 'kg',
    fiyat DECIMAL(10,3) NOT NULL,
    kur VARCHAR(3) DEFAULT 'TRY',
    gecerlilik_baslangic DATE DEFAULT CURRENT_DATE,
    gecerlilik_bitis DATE,
    aktif BOOLEAN DEFAULT TRUE,
    notlar TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tedarikci odeme gecmisi tablosu
CREATE TABLE IF NOT EXISTS tedarikci_odeme_gecmisi (
    id SERIAL PRIMARY KEY,
    tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE CASCADE,
    odeme_turu VARCHAR(20) NOT NULL CHECK (odeme_turu IN ('odeme', 'tahsilat', 'iade')),
    tutar DECIMAL(12,2) NOT NULL,
    kur VARCHAR(3) DEFAULT 'TRY',
    odeme_tarihi DATE DEFAULT CURRENT_DATE,
    odeme_yontemi VARCHAR(20) CHECK (odeme_yontemi IN ('nakit', 'banka', 'cek', 'senet', 'diger')),
    aciklama TEXT,
    belge_no VARCHAR(50),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik guncelleme icin trigger
CREATE OR REPLACE FUNCTION update_tedarikci_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tedarikciler_updated_at_trigger ON tedarikciler;
CREATE TRIGGER tedarikciler_updated_at_trigger
    BEFORE UPDATE ON tedarikciler
    FOR EACH ROW
    EXECUTE FUNCTION update_tedarikci_updated_at();

-- Fiyat listesi otomatik guncelleme
CREATE OR REPLACE FUNCTION update_fiyat_listesi_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS fiyat_listesi_updated_at_trigger ON tedarikci_fiyat_listeleri;
CREATE TRIGGER fiyat_listesi_updated_at_trigger
    BEFORE UPDATE ON tedarikci_fiyat_listeleri
    FOR EACH ROW
    EXECUTE FUNCTION update_fiyat_listesi_updated_at();

-- RLS (Row Level Security) politikalari
ALTER TABLE tedarikciler ENABLE ROW LEVEL SECURITY;
ALTER TABLE tedarikci_iletisim ENABLE ROW LEVEL SECURITY;
ALTER TABLE tedarikci_adresler ENABLE ROW LEVEL SECURITY;
ALTER TABLE tedarikci_fiyat_listeleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE tedarikci_odeme_gecmisi ENABLE ROW LEVEL SECURITY;

-- Tum kullanicilar okuyabilir
CREATE POLICY "Kullanicilar tedarikcileri gorebilir" ON tedarikciler
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar tedarikci iletisimi gorebilir" ON tedarikci_iletisim
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar tedarikci adreslerini gorebilir" ON tedarikci_adresler
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar fiyat listelerini gorebilir" ON tedarikci_fiyat_listeleri
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar odeme gecmisini gorebilir" ON tedarikci_odeme_gecmisi
    FOR SELECT USING (true);

-- Sadece admin ve user rolu ekleyebilir/guncelleyebilir
CREATE POLICY "Admin ve user tedarikci ekleyebilir" ON tedarikciler
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin ve user tedarikci guncelleyebilir" ON tedarikciler
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin tedarikci silebilir" ON tedarikciler
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Iletisim gecmisi ve diger tablolar icin politikalar
CREATE POLICY "Herkes tedarikci iletisimi ekleyebilir" ON tedarikci_iletisim
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin ve user fiyat listesi ekleyebilir" ON tedarikci_fiyat_listeleri
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

CREATE POLICY "Admin ve user odeme kaydedebilir" ON tedarikci_odeme_gecmisi
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

-- Indeksler (performans icin)
CREATE INDEX IF NOT EXISTS idx_tedarikciler_ad ON tedarikciler(ad);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_sirket ON tedarikciler(sirket);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_telefon ON tedarikciler(telefon);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_email ON tedarikciler(email);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_vergi_no ON tedarikciler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_durum ON tedarikciler(durum);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_tedarikci_tipi ON tedarikciler(tedarikci_tipi);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_faaliyet ON tedarikciler(faaliyet);
CREATE INDEX IF NOT EXISTS idx_tedarikci_iletisim_tedarikci_id ON tedarikci_iletisim(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_tedarikci_adresler_tedarikci_id ON tedarikci_adresler(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_fiyat_listeleri_tedarikci_id ON tedarikci_fiyat_listeleri(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_fiyat_listeleri_urun_kodu ON tedarikci_fiyat_listeleri(urun_kodu);
CREATE INDEX IF NOT EXISTS idx_odeme_gecmisi_tedarikci_id ON tedarikci_odeme_gecmisi(tedarikci_id);

-- Unique constraints (tekrar eden kayitlari onlemek icin)
-- Telefon unique constraint'i ekle ama hataya engel olmak icin once kontrol et
DO $$
BEGIN
    BEGIN
        ALTER TABLE tedarikciler ADD CONSTRAINT unique_tedarikci_telefon UNIQUE (telefon);
    EXCEPTION
        WHEN duplicate_table THEN
            -- Constraint zaten varsa, hicbir sey yapma
        WHEN others THEN
            RAISE NOTICE 'Telefon unique constraint eklenirken hata: %', SQLERRM;
    END;
END $$;

-- Email unique constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE tedarikciler ADD CONSTRAINT unique_tedarikci_email UNIQUE (email);
    EXCEPTION
        WHEN duplicate_table THEN
            -- Constraint zaten varsa, hicbir sey yapma
        WHEN others THEN
            RAISE NOTICE 'Email unique constraint eklenirken hata: %', SQLERRM;
    END;
END $$;

-- Vergi no unique constraint
DO $$
BEGIN
    BEGIN
        ALTER TABLE tedarikciler ADD CONSTRAINT unique_tedarikci_vergi_no UNIQUE (vergi_no);
    EXCEPTION
        WHEN duplicate_table THEN
            -- Constraint zaten varsa, hicbir sey yapma
        WHEN others THEN
            RAISE NOTICE 'Vergi No unique constraint eklenirken hata: %', SQLERRM;
    END;
END $$;

-- Ornek veri (test icin)
INSERT INTO tedarikciler (
    ad, sirket, telefon, cep_telefonu, email, adres, il, ilce, 
    tedarikci_tipi, faaliyet, durum, notlar, odeme_vadesi
) VALUES 
(
    'Mehmet KAYA', 'Kaya İplik San. Tic. Ltd. Şti.', '02165550101', '05321234567', 'info@kayaiplik.com', 
    'Sanayi Mahallesi, İplik Caddesi No:5', 'İstanbul', 'Pendik',
    'Üretici', 'İplik', 'aktif', 'Kaliteli pamuk ipliği tedarikçi', 30
),
(
    'Ayşe DEMİR', 'Demir Örgü Atölyesi', '02124455667', '05339876543', 'ayse@demirorgu.com',
    'Merkez Mahallesi, Örgü Sokak No:12', 'Bursa', 'Osmangazi', 
    'Hizmet Sağlayıcı', 'Tekstil', 'aktif', 'Hızlı örgü işleri', 15
),
(
    'Ali YILMAZ', 'Yılmaz Konfeksiyon', '02325556677', '05447788990', 'ali@yilmazkonfeksiyon.com',
    'Sanayi Sitesi, B Blok No:8', 'İzmir', 'Bornova', 
    'Hizmet Sağlayıcı', 'Tekstil', 'aktif', 'Kaliteli konfeksiyon işleri', 20
);

-- Ornek fiyat listeleri
INSERT INTO tedarikci_fiyat_listeleri (
    tedarikci_id, urun_kodu, urun_adi, birim, fiyat, kur
) VALUES 
(
    (SELECT id FROM tedarikciler WHERE ad = 'Mehmet KAYA' LIMIT 1),
    'PK001', 'Pamuk İplik 30/1', 'kg', 85.50, 'TRY'
),
(
    (SELECT id FROM tedarikciler WHERE ad = 'Mehmet KAYA' LIMIT 1),
    'PK002', 'Pamuk İplik 20/1', 'kg', 92.00, 'TRY'
),
(
    (SELECT id FROM tedarikciler WHERE ad = 'Ayşe DEMİR' LIMIT 1),
    'ORG001', 'Örgü İşçilik (Basit)', 'adet', 12.50, 'TRY'
),
(
    (SELECT id FROM tedarikciler WHERE ad = 'Ali YILMAZ' LIMIT 1),
    'KNF001', 'Konfeksiyon İşçilik', 'adet', 8.75, 'TRY'
);

-- Basari mesaji
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEDARİKÇİ YÖNETİMİ MODÜLÜ BAŞARIYLA KURULDU';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Oluşturulan tablolar:';
    RAISE NOTICE '- tedarikciler (ana tedarikçi kartları)';
    RAISE NOTICE '- tedarikci_iletisim (iletişim geçmişi)';
    RAISE NOTICE '- tedarikci_adresler (çoklu adres desteği)';
    RAISE NOTICE '- tedarikci_fiyat_listeleri (fiyat yönetimi)';
    RAISE NOTICE '- tedarikci_odeme_gecmisi (finansal takip)';
    RAISE NOTICE '';
    RAISE NOTICE 'Toplam tedarikçi sayısı: %', (SELECT COUNT(*) FROM tedarikciler);
    RAISE NOTICE 'Üretici tedarikçiler: %', (SELECT COUNT(*) FROM tedarikciler WHERE tedarikci_tipi = 'Üretici');
    RAISE NOTICE 'Hizmet Sağlayıcı tedarikçiler: %', (SELECT COUNT(*) FROM tedarikciler WHERE tedarikci_tipi = 'Hizmet Sağlayıcı');
    RAISE NOTICE '========================================';
END $$;
