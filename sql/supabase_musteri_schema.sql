-- ================================================================================================
-- MÜŞTERİ YÖNETİMİ MODÜLÜ - SUPABASE ŞEMASI (GÜNCEL)
-- ================================================================================================
-- Bu script mevcut sisteme müşteri yönetimi modülü ekler
-- MEVCUT SİSTEMİ BOZMADAN yeni tablolar oluşturur
-- Flutter MusteriModel ile uyumlu şema
-- ================================================================================================

-- Müşteri kartları tablosu
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

-- Müşteri iletişim geçmişi tablosu
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

-- Müşteri adres tablosu (çoklu adres desteği için)
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

-- Otomatik güncelleme için trigger
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

-- RLS (Row Level Security) politikaları
ALTER TABLE musteriler ENABLE ROW LEVEL SECURITY;
ALTER TABLE musteri_iletisim ENABLE ROW LEVEL SECURITY;
ALTER TABLE musteri_adresler ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar musterileri gorebilir" ON musteriler
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar musteri iletisimi gorebilir" ON musteri_iletisim
    FOR SELECT USING (true);

CREATE POLICY "Kullanicilar musteri adreslerini gorebilir" ON musteri_adresler
    FOR SELECT USING (true);

-- Sadece admin ve user rolü ekleyebilir/güncelleyebilir
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

-- İletişim geçmişi için politikalar
CREATE POLICY "Herkes musteri iletisimi ekleyebilir" ON musteri_iletisim
    FOR INSERT WITH CHECK (true);

-- Adres için politikalar  
CREATE POLICY "Admin ve user musteri adresi ekleyebilir" ON musteri_adresler
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

-- İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_musteriler_ad ON musteriler(ad);
CREATE INDEX IF NOT EXISTS idx_musteriler_sirket ON musteriler(sirket);
CREATE INDEX IF NOT EXISTS idx_musteriler_telefon ON musteriler(telefon);
CREATE INDEX IF NOT EXISTS idx_musteriler_email ON musteriler(email);
CREATE INDEX IF NOT EXISTS idx_musteriler_vergi_no ON musteriler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_musteriler_durum ON musteriler(durum);
CREATE INDEX IF NOT EXISTS idx_musteriler_musteri_tipi ON musteriler(musteri_tipi);
CREATE INDEX IF NOT EXISTS idx_musteri_iletisim_musteri_id ON musteri_iletisim(musteri_id);
CREATE INDEX IF NOT EXISTS idx_musteri_adresler_musteri_id ON musteri_adresler(musteri_id);

-- Unique constraints (tekrar eden kayıtları önlemek için)
ALTER TABLE musteriler ADD CONSTRAINT IF NOT EXISTS unique_telefon UNIQUE (telefon);
ALTER TABLE musteriler ADD CONSTRAINT IF NOT EXISTS unique_email UNIQUE (email);
ALTER TABLE musteriler ADD CONSTRAINT IF NOT EXISTS unique_vergi_no UNIQUE (vergi_no);

-- Örnek veri (test için)
INSERT INTO musteriler (
    ad, soyad, telefon, email, adres, il, ilce, 
    musteri_tipi, durum, notlar
) VALUES 
(
    'Ahmet', 'YILMAZ', '05321234567', 'ahmet.yilmaz@email.com', 
    'Örnek Mahallesi, Örnek Sokak No:1', 'İstanbul', 'Kadıköy',
    'bireysel', 'aktif', 'Düzenli müşteri'
),
(
    'Fatma', 'KAYA', '05339876543', 'fatma.kaya@email.com',
    'Test Caddesi No:25', 'İstanbul', 'Beyoğlu', 
    'bireysel', 'aktif', 'Hızlı teslimat istiyor'
);

INSERT INTO musteriler (
    ad, sirket, telefon, email, adres, il, ilce, vergi_no, vergi_dairesi,
    musteri_tipi, durum, kredi_limiti, notlar
) VALUES 
(
    'Mehmet DEMIR', 'Örnek Tekstil Ltd. Şti.', '02165550001', 'info@ornektekstil.com', 
    'Sanayi Mahallesi, Fabrika Caddesi No:15', 'İstanbul', 'Ümraniye',
    '1234567890', 'Ümraniye VD', 'kurumsal', 'aktif', 50000.00,
    'Önemli kurumsal müşteri, büyük siparişler veriyor'
);

COMMIT;

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'MÜŞTERİ YÖNETİMİ MODÜLÜ BAŞARIYLA KURULDU';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Oluşturulan tablolar:';
    RAISE NOTICE '- musteriler (ana müşteri kartları)';
    RAISE NOTICE '- musteri_iletisim (iletişim geçmişi)';
    RAISE NOTICE '- musteri_adresler (çoklu adres desteği)';
    RAISE NOTICE '';
    RAISE NOTICE 'Toplam müşteri sayısı: %', (SELECT COUNT(*) FROM musteriler);
    RAISE NOTICE '========================================';
END $$;
