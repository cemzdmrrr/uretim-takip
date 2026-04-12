-- SADECE AKSESUARLAR TABLOSUNU OLUŞTUR
DROP TABLE IF EXISTS aksesuarlar CASCADE;

CREATE TABLE aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    ad TEXT NOT NULL,
    kategori TEXT NOT NULL,
    renk TEXT,
    renk_kodu TEXT,
    desen TEXT,
    olcu_tipi TEXT CHECK (olcu_tipi IN ('beden', 'uzunluk', 'genislik', 'capi', 'yok')),
    beden TEXT,
    uzunluk_cm DECIMAL,
    genislik_cm DECIMAL,
    capi_mm DECIMAL,
    birim TEXT NOT NULL DEFAULT 'adet',
    stok_miktari INTEGER NOT NULL DEFAULT 0,
    minimum_stok INTEGER DEFAULT 10,
    maksimum_stok INTEGER,
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    aciklama TEXT,
    malzeme TEXT,
    marka TEXT,
    tedarikci_kodu TEXT,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndex ekle
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_kategori ON aksesuarlar(kategori);

-- Trigger ekle
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_aksesuarlar_updated_at 
    BEFORE UPDATE ON aksesuarlar 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Test verisi ekle
INSERT INTO aksesuarlar (sku, ad, kategori, renk, renk_kodu, olcu_tipi, beden, capi_mm, birim, stok_miktari, minimum_stok, birim_fiyat, malzeme, aciklama) 
VALUES 
('TEST001', 'Test Düğme', 'düğme', 'beyaz', '#FFFFFF', 'capi', null, 15, 'adet', 100, 10, 0.50, 'plastik', 'Test için örnek düğme')
ON CONFLICT (sku) DO NOTHING;
