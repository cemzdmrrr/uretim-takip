-- =============================================
-- KASA BANKA HAREKETLERİ TABLOSU
-- =============================================

CREATE TABLE IF NOT EXISTS kasa_banka_hareketleri (
    id SERIAL PRIMARY KEY,
    hesap_id INTEGER,
    hareket_tarihi DATE NOT NULL,
    aciklama TEXT,
    giren_tutar DECIMAL(15,2) DEFAULT 0,
    cikan_tutar DECIMAL(15,2) DEFAULT 0,
    bakiye DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_hesap_id ON kasa_banka_hareketleri(hesap_id);
CREATE INDEX IF NOT EXISTS idx_kasa_banka_hareketleri_hareket_tarihi ON kasa_banka_hareketleri(hareket_tarihi);
