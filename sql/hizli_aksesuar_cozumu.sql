-- HIZLI ÇÖZÜM: Sadece aksesuarlar tablosunu oluştur
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- Önce tabloyu sil (varsa)
DROP TABLE IF EXISTS aksesuarlar CASCADE;

-- Yeni tabloyu oluştur
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
    aciklama TEXT,  -- ÖNEMLİ: Bu sütun Flutter kodunda kullanılıyor
    malzeme TEXT,
    marka TEXT,
    tedarikci_kodu TEXT,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndex oluştur
CREATE INDEX idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX idx_aksesuarlar_kategori ON aksesuarlar(kategori);
CREATE INDEX idx_aksesuarlar_renk ON aksesuarlar(renk);

-- Trigger oluştur
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
('PG910-1024-18', '18mm Düğme', 'düğme', '1024', '#FF6B6B', 'capi', null, 18, 'adet', 5000, 100, 0.75, 'plastik', 'Gömlek için plastik düğme'),
('BTN001-M', 'Metal Düğme', 'düğme', 'gümüş', '#C0C0C0', 'beden', 'M', 20, 'adet', 2500, 50, 1.25, 'metal', 'Ceket için metal düğme'),
('FRM075-S', 'Deri Kemer', 'kemer', 'kahverengi', '#8B4513', 'uzunluk', 'S', 75, 'adet', 150, 10, 45.00, 'deri', '75cm deri kemer'),
('LBL001-L', 'Marka Etiketi', 'etiket', 'beyaz', '#FFFFFF', 'beden', 'L', null, 'adet', 1000, 50, 2.50, 'kumaş', 'Logo baskılı kumaş etiket');
