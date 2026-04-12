-- Ã–LÃ‡ÃœLÃœ VE BEDENLÄ° AKSESUARLAR Ä°Ã‡Ä°N VERÄ°TABANI ÅEMASI
-- GÃ¼ncellenmiÅŸ Aksesuar YÃ¶netim Sistemi

-- 1. AKSESUARLAR TABLOSU (GÃ¼ncellenmiÅŸ)
CREATE TABLE IF NOT EXISTS aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL, -- ÃœrÃ¼n kodu (PG910, BTN001, vb.)
    ad TEXT NOT NULL, -- Aksesuar adÄ±
    kategori TEXT NOT NULL, -- dÃ¼ÄŸme, fermuar, etiket, kemer, ÅŸapka
    
    -- RENK VE DESEN BÄ°LGÄ°LERÄ°
    renk TEXT, -- 1024, kÄ±rmÄ±zÄ±, mavi, desenli
    renk_kodu TEXT, -- hex kodu veya pantone kodu
    desen TEXT, -- Ã§izgili, puantiyeli, dÃ¼z
    
    -- Ã–LÃ‡Ãœ VE BEDEN BÄ°LGÄ°LERÄ°
    olcu_tipi TEXT CHECK (olcu_tipi IN ('beden', 'uzunluk', 'genislik', 'capi', 'yok')), -- Ã–lÃ§Ã¼ tÃ¼rÃ¼
    beden TEXT, -- S, M, L, XL, XXL
    uzunluk_cm DECIMAL, -- 75 cm, 120 cm
    genislik_cm DECIMAL, -- 5 cm, 10 cm
    capi_mm DECIMAL, -- 18 mm, 25 mm (dÃ¼ÄŸme Ã§apÄ±)
    
    -- STOK VE FÄ°YAT BÄ°LGÄ°LERÄ°
    birim TEXT NOT NULL DEFAULT 'adet', -- adet, metre, kg, gr
    stok_miktari INTEGER NOT NULL DEFAULT 0, -- GÃ¼ncel stok
    minimum_stok INTEGER DEFAULT 10, -- Minimum stok seviyesi
    maksimum_stok INTEGER, -- Maksimum stok seviyesi
    birim_fiyat DECIMAL(10,2) DEFAULT 0.00,
    
    -- AÃ‡IKLAMA VE Ã–ZELLIKLER
    aciklama TEXT, -- DetaylÄ± aÃ§Ä±klama
    malzeme TEXT, -- plastik, metal, kumaÅŸ, deri
    marka TEXT, -- YKK, Coats, vb.
    tedarikci_kodu TEXT, -- TedarikÃ§ideki Ã¼rÃ¼n kodu
    
    -- SÄ°STEM BÄ°LGÄ°LERÄ°
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. MODELLER TABLOSU (Mevcut tablo yapÄ±sÄ±nÄ± kullan - sadece eksik kolonlarÄ± ekle)
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS kategori TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS sezon TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS aciklama TEXT;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT true;
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE modeller ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. MODEL-AKSESUAR Ä°LÄ°ÅKÄ°SÄ° TABLOSU
CREATE TABLE IF NOT EXISTS model_aksesuarlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE, -- INTEGER olarak deÄŸiÅŸtirdik
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- KULLANIM BÄ°LGÄ°LERÄ°
    kullanim_miktari DECIMAL NOT NULL DEFAULT 1, -- Model baÅŸÄ±na kaÃ§ adet/metre
    zorunlu BOOLEAN DEFAULT true, -- Bu aksesuar modelde zorunlu mu?
    alternatif_grup TEXT, -- Alternatif aksesuarlar iÃ§in grup kodu
    
    -- KONUM BÄ°LGÄ°SÄ°
    kullanim_yeri TEXT, -- yaka, kol, bel, dÃ¼ÄŸme, vb.
    sira_no INTEGER, -- AksesuarÄ±n modeldeki sÄ±rasÄ±
    
    -- NOTLAR
    notlar TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Her model-aksesuar kombinasyonu benzersiz olmalÄ±
    UNIQUE(model_id, aksesuar_id)
);

-- 4. STOK HAREKETLERÄ° TABLOSU
CREATE TABLE IF NOT EXISTS stok_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    
    -- HAREKET BÄ°LGÄ°LERÄ°
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'duzeltme', 'fire', 'sayim')),
    miktar INTEGER NOT NULL, -- +/- deÄŸer olabilir
    onceki_stok INTEGER NOT NULL,
    yeni_stok INTEGER NOT NULL,
    
    -- REFERANS BÄ°LGÄ°LERÄ°
    model_id INTEGER REFERENCES modeller(id), -- INTEGER olarak deÄŸiÅŸtirdik
    siparis_no TEXT, -- SipariÅŸ numarasÄ±
    fatura_no TEXT, -- Fatura numarasÄ±
    
    -- AÃ‡IKLAMA
    aciklama TEXT,
    
    -- KULLANICI BÄ°LGÄ°SÄ°
    kullanici_id UUID, -- Kim yaptÄ± bu hareketi
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TEDARÄ°KÃ‡Ä°LER TABLOSU (Mevcut tablo yapÄ±sÄ±nÄ± kullan - sadece eksik kolonlarÄ± ekle)
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS iletisim_kisi TEXT;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS notlar TEXT;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS aktif BOOLEAN DEFAULT true;
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE tedarikciler ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 6. AKSESUAR-TEDARÄ°KÃ‡Ä° Ä°LÄ°ÅKÄ°SÄ°
CREATE TABLE IF NOT EXISTS aksesuar_tedarikciler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aksesuar_id UUID NOT NULL REFERENCES aksesuarlar(id) ON DELETE CASCADE,
    tedarikci_id INTEGER NOT NULL REFERENCES tedarikciler(id) ON DELETE CASCADE, -- INTEGER olarak deÄŸiÅŸtirdik
    tedarikci_urun_kodu TEXT, -- TedarikÃ§ideki Ã¼rÃ¼n kodu
    minimum_siparis INTEGER, -- Minimum sipariÅŸ miktarÄ±
    teslimat_suresi INTEGER, -- GÃ¼n cinsinden teslimat sÃ¼resi
    birim_fiyat DECIMAL(10,2),
    para_birimi TEXT DEFAULT 'TRY',
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(aksesuar_id, tedarikci_id)
);

-- 7. Ä°NDEXLER (Performans iÃ§in)
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_sku ON aksesuarlar(sku);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_kategori ON aksesuarlar(kategori);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_renk ON aksesuarlar(renk);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_beden ON aksesuarlar(beden);
CREATE INDEX IF NOT EXISTS idx_aksesuarlar_stok ON aksesuarlar(stok_miktari);
CREATE INDEX IF NOT EXISTS idx_modeller_kodu ON modeller(model_kodu);
CREATE INDEX IF NOT EXISTS idx_stok_hareketleri_aksesuar ON stok_hareketleri(aksesuar_id);
CREATE INDEX IF NOT EXISTS idx_stok_hareketleri_tarih ON stok_hareketleri(created_at);

-- 8. TRÄ°GGERLAR (Otomatik gÃ¼ncellemeler iÃ§in)

-- Updated_at otomatik gÃ¼ncelleme
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

-- 9. Ã–RNEK VERÄ°LER

-- Ã–rnek Aksesuarlar (GÃ¼venli INSERT)
INSERT INTO aksesuarlar (sku, ad, kategori, renk, renk_kodu, olcu_tipi, beden, capi_mm, birim, stok_miktari, minimum_stok, birim_fiyat, malzeme, aciklama) 
VALUES 
('PG910-1024-18', '18mm DÃ¼ÄŸme', 'dÃ¼ÄŸme', '1024', '#FF6B6B', 'capi', null, 18, 'adet', 5000, 100, 0.75, 'plastik', 'GÃ¶mlek iÃ§in plastik dÃ¼ÄŸme'),
('BTN001-M', 'Metal DÃ¼ÄŸme', 'dÃ¼ÄŸme', 'gÃ¼mÃ¼ÅŸ', '#C0C0C0', 'beden', 'M', 20, 'adet', 2500, 50, 1.25, 'metal', 'Ceket iÃ§in metal dÃ¼ÄŸme'),
('FRM075-S', 'Deri Kemer', 'kemer', 'kahverengi', '#8B4513', 'uzunluk', 'S', 75, 'adet', 150, 10, 45.00, 'deri', '75cm deri kemer'),
('LBL001-L', 'Marka Etiketi', 'etiket', 'beyaz', '#FFFFFF', 'beden', 'L', null, 'adet', 1000, 50, 2.50, 'kumaÅŸ', 'Logo baskÄ±lÄ± kumaÅŸ etiket')
ON CONFLICT (sku) DO NOTHING;

-- Ã–rnek Modeller (Mevcut modelleri kontrol et, yoksa ekle)
INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR001', 'Klasik GÃ¶mlek', 'gÃ¶mlek', '2024-yaz', 'Erkek klasik beyaz gÃ¶mlek'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR001');

INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR002', 'Casual Pantolon', 'pantolon', '2024-yaz', 'Erkek casual pantolon'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR002');

INSERT INTO modeller (model_kodu, model_adi, kategori, sezon, aciklama)
SELECT 'TR003', 'Blazer Ceket', 'ceket', '2024-sonbahar', 'KadÄ±n blazer ceket'
WHERE NOT EXISTS (SELECT 1 FROM modeller WHERE model_kodu = 'TR003');

-- 10. YARDIMCI VÄ°EW'LAR

-- Aksesuar detay gÃ¶rÃ¼nÃ¼mÃ¼
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
        WHEN a.stok_miktari <= (a.minimum_stok * 2) THEN 'DÃœÅÃœK'
        ELSE 'NORMAL'
    END as stok_durumu
FROM aksesuarlar a
WHERE a.aktif = true;

-- Model aksesuar Ã¶zeti
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
