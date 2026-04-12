-- =============================================
-- KASA BANKA HAREKETLERİ FİX
-- =============================================

-- Eksik kolonları ekle
ALTER TABLE kasa_banka_hareketleri
ADD COLUMN IF NOT EXISTS kasa_banka_id INTEGER REFERENCES kasa_banka_hesaplari(id),
ADD COLUMN IF NOT EXISTS hareket_tipi VARCHAR(20) DEFAULT 'giris',
ADD COLUMN IF NOT EXISTS islem_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS kategori VARCHAR(50),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_kasa_banka_id ON kasa_banka_hareketleri(kasa_banka_id);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_hareket_tipi ON kasa_banka_hareketleri(hareket_tipi);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_islem_tarihi ON kasa_banka_hareketleri(islem_tarihi);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_kategori ON kasa_banka_hareketleri(kategori);
