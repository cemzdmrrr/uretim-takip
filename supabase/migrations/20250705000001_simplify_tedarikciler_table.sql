-- ================================================================================================
-- TEDARIKCI TABLOSUNU SADELEŞTİRME MIGRATION
-- ================================================================================================
-- Bu migration mevcut tedarikçi tablosunu sadeleştirir
-- Sadece gerekli alanları bırakır, diğer tüm alanları kaldırır
-- ================================================================================================

-- Mevcut tabloyu yedekle (isteğe bağlı)
-- CREATE TABLE tedarikciler_backup AS SELECT * FROM tedarikciler;

-- Mevcut tabloyu sil ve yeniden oluştur
DROP TABLE IF EXISTS tedarikciler CASCADE;

-- Yeni sadeleştirilmiş tedarikçi tablosu
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

-- RLS politikaları
ALTER TABLE tedarikciler ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar okuyabilir
CREATE POLICY "Kullanicilar tedarikcileri gorebilir" ON tedarikciler
    FOR SELECT USING (true);

-- Admin ve user rolü ekleyebilir/güncelleyebilir
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

-- Performans için indeksler
CREATE INDEX IF NOT EXISTS idx_tedarikciler_ad ON tedarikciler(ad);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_sirket ON tedarikciler(sirket);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_telefon ON tedarikciler(telefon);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_email ON tedarikciler(email);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_vergi_no ON tedarikciler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_durum ON tedarikciler(durum);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_tedarikci_tipi ON tedarikciler(tedarikci_tipi);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_faaliyet ON tedarikciler(faaliyet);

-- Test verisi
INSERT INTO tedarikciler (
    ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum, vergi_no, tc_kimlik, iban_no
) VALUES 
(
    'Test', 'Tedarikçi', 'Test Şirketi', '05551234567', 'test@test.com', 
    'Üretici', 'Test', 'aktif', '1234567890', '12345678901', 'TR330006100519786457841326'
);
