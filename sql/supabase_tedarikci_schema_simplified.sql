-- ================================================================================================
-- SADELEŞTIRILMIŞ TEDARIKCI YONETIMI MODULU - SUPABASE SEMASI
-- ================================================================================================
-- Bu script sadece gerekli alanları içeren tedarikçi tablosunu oluşturur
-- Flutter TedarikciModel ile birebir uyumludur
-- ================================================================================================

-- Mevcut tabloyu sil ve yeniden oluştur
DROP TABLE IF EXISTS tedarikciler CASCADE;

-- Basitleştirilmiş tedarikçi tablosu
CREATE TABLE tedarikciler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100),
    sirket VARCHAR(255),
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    tedarikci_tipi VARCHAR(50) DEFAULT 'Üretici',
    faaliyet VARCHAR(50),
    durum VARCHAR(20) DEFAULT 'aktif',
    vergi_no VARCHAR(20),
    tc_kimlik VARCHAR(11),
    iban_no VARCHAR(34),
    kayit_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Otomatik güncelleme için trigger
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

-- RLS (Row Level Security) politikaları
ALTER TABLE tedarikciler ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar tedarikcileri gorebilir" ON tedarikciler
    FOR SELECT USING (true);

-- Sadece admin ve user rolü ekleyebilir/güncelleyebilir
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

-- İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_tedarikciler_ad ON tedarikciler(ad);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_sirket ON tedarikciler(sirket);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_telefon ON tedarikciler(telefon);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_email ON tedarikciler(email);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_vergi_no ON tedarikciler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_durum ON tedarikciler(durum);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_tedarikci_tipi ON tedarikciler(tedarikci_tipi);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_faaliyet ON tedarikciler(faaliyet);

-- Örnek veri (test için)
INSERT INTO tedarikciler (
    ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum, vergi_no, tc_kimlik, iban_no
) VALUES 
(
    'Mehmet', 'KAYA', 'Kaya İplik San. Tic. Ltd. Şti.', '02165550101', 'info@kayaiplik.com', 
    'Üretici', 'İplik', 'aktif', '1234567890', '12345678901', 'TR330006100519786457841326'
),
(
    'Ayşe', 'DEMİR', 'Demir Örgü Atölyesi', '02124455667', 'ayse@demirorgu.com',
    'Hizmet Sağlayıcı', 'Tekstil', 'aktif', '2345678901', '23456789012', 'TR640006200519786457841327'
),
(
    'Ali', 'YILMAZ', 'Yılmaz Konfeksiyon', '02325556677', 'ali@yilmazkonfeksiyon.com',
    'Hizmet Sağlayıcı', 'Tekstil', 'aktif', '3456789012', '34567890123', 'TR950006300519786457841328'
);

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SADELEŞTİRİLMİŞ TEDARİKÇİ MODÜLÜ KURULDU';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Oluşturulan tablo:';
    RAISE NOTICE '- tedarikciler (sadeleştirilmiş ana tablo)';
    RAISE NOTICE '';
    RAISE NOTICE 'Toplam tedarikçi sayısı: %', (SELECT COUNT(*) FROM tedarikciler);
    RAISE NOTICE '========================================';
END $$;
