-- ÖLÇÜLÜ VE BEDENLİ AKSESUARLAR İÇİN VERİTABANI ŞEMASI
-- Güncellenmiş Aksesuar Yönetim Sistemi

-- 1. AKSESUARLAR TABLOSU (Güncellenmiş)
CREATE TABLE IF NOT EXISTS aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL, -- Ürün kodu (PG910, BTN001, vb.)
    ad TEXT NOT NULL, -- Aksesuar adı
    kategori TEXT NOT NULL, -- düğme, fermuar, etiket, kemer, şapka
    
    -- RENK VE DESEN BİLGİLERİ
    renk TEXT, -- 1024, kırmızı, mavi, desenli
    renk_kodu TEXT, -- hex kodu veya pantone kodu
    desen TEXT, -- çizgili, puantiyeli, düz
    
    -- ÖLÇÜ VE BEDEN BİLGİLERİ
    olcu_tipi TEXT CHECK (olcu_tipi IN ('beden', 'uzunluk', 'genislik', 'capi', 'yok')), -- Ölçü türü
    beden TEXT, -- S, M, L, XL, XXL
    uzunluk_cm DECIMAL, -- 75 cm, 120 cm
    genislik_cm DECIMAL, -- 5 cm, 10 cm
    capi_mm DECIMAL, -- 18 mm, 25 mm (düğme çapı)
    
    -- STOK VE FİYAT BİLGİLERİ
    birim TEXT NOT NULL DEFAULT 'adet', -- adet, metre, kg, gr
    stok_miktari INTEGER NOT NULL DEFAULT 0, -- Güncel stok
    minimum_stok INTEGER DEFAULT 10, -- Minimum stok seviyesi
    maksimum_stok INTEGER, -- Maksimum stok seviyesi
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    
    -- AÇIKLAMA VE ÖZELLIKLER
    aciklama TEXT, -- Detaylı açıklama
    malzeme TEXT, -- plastik, metal, kumaş, deri
    marka TEXT, -- YKK, Coats, vb.
    tedarikci_kodu TEXT, -- Tedarikçideki ürün kodu
    
    -- SİSTEM BİLGİLERİ
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. MODELLER TABLOSU (Mevcut tablo yapısını kullan - sadece eksik kolonları ekle)
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS kategori TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS sezon TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS aciklama TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT true;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. MODEL-AKSESUAR İLİŞKİSİ TABLOSU
CREATE TABLE IF NOT EXISTS model_aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE, -- INTEGER olarak değiştirdik
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- KULLANIM BİLGİLERİ
    kullanim_miktari DECIMAL NOT NULL DEFAULT 1, -- Model başına kaç adet/metre
    zorunlu BOOLEAN DEFAULT true, -- Bu aksesuar modelde zorunlu mu?
    alternatif_grup TEXT, -- Alternatif aksesuarlar için grup kodu
    
    -- KONUM BİLGİSİ
    kullanim_yeri TEXT, -- yaka, kol, bel, düğme, vb.
    sira_no INTEGER, -- Aksesuarın modeldeki sırası
    
    -- NOTLAR
    notlar TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Her model-aksesuar kombinasyonu benzersiz olmalı
    UNIQUE(model_id, aksesuar_id)
);

-- 4. STOK HAREKETLERİ TABLOSU
CREATE TABLE IF NOT EXISTS stok_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- HAREKET BİLGİLERİ
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'duzeltme', 'fire', 'sayim')),
    miktar INTEGER NOT NULL, -- +/- değer olabilir
    onceki_stok INTEGER NOT NULL,
    yeni_stok INTEGER NOT NULL,
    
    -- REFERANS BİLGİLERİ
    model_id INTEGER REFERENCES modeller(id), -- INTEGER olarak değiştirdik
    siparis_no TEXT, -- Sipariş numarası
    fatura_no TEXT, -- Fatura numarası
    
    -- AÇIKLAMA
    aciklama TEXT,
    
    -- KULLANICI BİLGİSİ
    kullanici_id UUID, -- Kim yaptı bu hareketi
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TEDARİKÇİLER TABLOSU (Mevcut tablo yapısını kullan - sadece eksik kolonları ekle)
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS iletisim_kisi TEXT;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS notlar TEXT;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT true;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 6. AKSESUAR-TEDARİKÇİ İLİŞKİSİ
CREATE TABLE IF NOT EXISTS aksesuar_tedarikciler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    tedarikci_id INTEGER NOT NULL REFERENCES tedarikciler(id) ON DELETE CASCADE, -- INTEGER olarak değiştirdik
    tedarikci_urun_kodu TEXT, -- Tedarikçideki ürün kodu
    minimum_siparis INTEGER, -- Minimum sipariş miktarı
    teslimat_suresi INTEGER, -- Gün cinsinden teslimat süresi
    birim_fiyat DECIMAL(10,2),
    para_birimi TEXT DEFAULT 'TRY',
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(aksesuar_id, tedarikci_id)
);

-- 7. İNDEXLER (Performans için)
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_kategori ON aksesuarlar(kategori);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_renk ON aksesuarlar(renk);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_beden ON aksesuarlar(beden);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_stok ON aksesuarlar(stok_miktari);
CREATE INDEX IF NOT EXISTS idx_modeller_kodu ON modeller(model_kodu);
CREATE INDEX IF NOT EXISTS idx_stok_hareketleri_aksesuar ON stok_hareketleri(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_stok_hareketleri_tarih ON stok_hareketleri(created_at);

-- 8. TRİGGERLAR (Otomatik güncellemeler için)

-- Updated_at otomatik güncelleme
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

CREATE TRIGGER update_modeller_updated_at 
    BEFORE UPDATE ON modeller 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tedarikciler_updated_at 
    BEFORE UPDATE ON tedarikciler 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. ÖRNEK VERİLER

-- Örnek Aksesuarlar (Güvenli INSERT)
INSERT INTO aksesuarlar (sku, ad, kategori, renk, renk_kodu, olcu_tipi, beden, capi_mm, birim, stok_miktari, minimum_stok, birim_fiyat, malzeme, aciklama) 
VALUES 
('PG910-1024-18', '18mm Düğme', 'düğme', '1024', '#FF6B6B', 'capi', null, 18, 'adet', 5000, 100, 0.75, 'plastik', 'Gömlek için plastik düğme'),
('BTN001-M', 'Metal Düğme', 'düğme', 'gümüş', '#C0C0C0', 'beden', 'M', 20, 'adet', 2500, 50, 1.25, 'metal', 'Ceket için metal düğme'),
('FRM075-S', 'Deri Kemer', 'kemer', 'kahverengi', '#8B4513', 'uzunluk', 'S', 75, 'adet', 150, 10, 45.00, 'deri', '75cm deri kemer'),
('LBL001-L', 'Marka Etiketi', 'etiket', 'beyaz', '#FFFFFF', 'beden', 'L', null, 'adet', 1000, 50, 2.50, 'kumaş', 'Logo baskılı kumaş etiket')
ON CONFLICT (sku) DO NOTHING;

-- Örnek Modeller (Mevcut modelleri kontrol et, yoksa ekle)
INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR001', 'Klasik Gömlek', 'gömlek', '2024-yaz', 'Erkek klasik beyaz gömlek'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR001');

INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR002', 'Casual Pantolon', 'pantolon', '2024-yaz', 'Erkek casual pantolon'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR002');

INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR003', 'Blazer Ceket', 'ceket', '2024-sonbahar', 'Kadın blazer ceket'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR003');

-- 10. YARDIMCI VİEW'LAR

-- Aksesuar detay görünümü
CREATE OR REPLACE VIEW aksesuar_detay AS
SELECT 
    a.*,
    CASE 
        WHEN a.olcu_tipi = 'beden' AND a.beden IS NOT NULL THEN a.beden
        WHEN a.olcu_tipi = 'uzunluk' AND a.uzunluk_cm IS NOT NULL THEN a.uzunluk_cm || ' cm'
        WHEN a.olcu_tipi = 'genislik' AND a.genislik_cm IS NOT NULL THEN a.genislik_cm || ' cm'
        WHEN a.olcu_tipi = 'capi' AND a.capi_mm IS NOT NULL THEN a.capi_mm || ' mm'
        ELSE 'Standart'
    END as olcu_bilgisi,
    CASE 
        WHEN a.stok_miktari <= a.minimum_stok THEN 'KRITIK'
        WHEN a.stok_miktari <= (a.minimum_stok * 2) THEN 'DÜŞÜK'
        ELSE 'NORMAL'
    END as stok_durumu
FROM aksesuarlar a
WHERE a.aktif = true;

-- Model aksesuar özeti
CREATE OR REPLACE VIEW model_aksesuar_ozet AS
SELECT 
    m.model_kodu,
    m.model_adi,
    a.sku,
    a.ad as aksesuar_adi,
    a.kategori,
    ma.kullanim_miktari,
    ma.kullanim_yeri,
    a.stok_miktari,
    (a.stok_miktari / ma.kullanim_miktari)::INTEGER as uretebilir_adet,
    ma.zorunlu
FROM modeller m
JOIN model_aksesuarlar ma ON m.id = ma.model_id
JOIN aksesuarlar a ON ma.aksesuar_id = a.id
WHERE m.aktif = true AND a.aktif = true
ORDER BY m.model_kodu, ma.sira_no;
