-- Triko Takip Tablosu - Yeni Prototip
-- Önce mevcut tabloyu yedekleyelim
CREATE TABLE IF NOT EXISTS triko_takip_backup AS SELECT * FROM triko_takip;

-- Mevcut tabloyu sil ve yeniden oluştur (geliştirme ortamında)
DROP TABLE IF EXISTS triko_takip CASCADE;

-- Ana triko takip tablosu
CREATE TABLE triko_takip (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 1. Temel Model Bilgileri
    marka TEXT NOT NULL,
    model_no TEXT NOT NULL UNIQUE, -- Benzersiz model kodu
    model_adi TEXT NOT NULL,
    sezon TEXT CHECK (sezon IN ('İlkbahar/Yaz', 'Sonbahar/Kış', 'Tüm Sezon')),
    koleksiyon TEXT,
    
    -- 2. Triko/Dokuma Ürün Detayları
    urun_kategorisi TEXT CHECK (urun_kategorisi IN ('Kazak', 'Hırka', 'Yelek', 'Elbise', 'Pantolon', 'Diğer')),
    triko_tipi TEXT CHECK (triko_tipi IN ('Düz örgü', 'Rib', 'Kablo', 'Jakarlı', 'Fair Isle', 'Diğer')),
    cinsiyet TEXT CHECK (cinsiyet IN ('Erkek', 'Kadın', 'Çocuk', 'Unisex')),
    yas_grubu TEXT CHECK (yas_grubu IN ('Yetişkin', 'Çocuk (2-12)', 'Bebek (0-2)')),
    yaka_tipi TEXT CHECK (yaka_tipi IN ('Bisiklet yaka', 'V yaka', 'Polo yaka', 'Balıkçı yaka', 'Diğer')),
    kol_tipi TEXT CHECK (kol_tipi IN ('Uzun kol', 'Kısa kol', 'Kolsuz', '3/4 kol')),
    
    -- 3. İplik ve Materyal Bilgileri
    ana_iplik_turu TEXT CHECK (ana_iplik_turu IN ('Pamuk', 'Yün', 'Akrilik', 'Kaşmir', 'Alpaka', 'Diğer')),
    iplik_karisimi TEXT, -- %100 Pamuk, %50 Pamuk %50 Akrilik vs.
    iplik_kalinligi TEXT CHECK (iplik_kalinligi IN ('Fine (İnce)', 'Medium (Orta)', 'Chunky (Kalın)')),
    iplik_markasi TEXT,
    iplik_renk_kodu TEXT,
    iplik_numarasi TEXT, -- Ne 20/1, Ne 30/1 vs.
    
    -- 4. Renk ve Desen
    ana_renkler TEXT[], -- Çoklu renk seçimi için array
    desen_tipi TEXT CHECK (desen_tipi IN ('Düz', 'Çizgili', 'Noktalı', 'Jakarlı desen', 'Argyle', 'Diğer')),
    desen_detayi TEXT,
    renk_kombinasyonu TEXT,
    
    -- 5. Beden ve Ölçü Bilgileri (JSON olarak)
    beden_dagilimi JSONB, -- {"XS": 30, "S": 80, "M": 120, "L": 100, "XL": 70, "XXL": 20}
    toplam_adet INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN beden_dagilimi IS NOT NULL THEN
                (SELECT SUM(value::integer) FROM jsonb_each_text(beden_dagilimi))
            ELSE 0
        END
    ) STORED,
    urun_grami DECIMAL(10,2), -- 350g vs.
    
    -- 6. Üretim Zinciri
    orgu_firmasi TEXT,
    iplik_tedarikci TEXT,
    boyahane TEXT,
    ilik_dugme_metal_aksesuar_firmasi TEXT,
    konfeksiyon_firmasi TEXT,
    utu_pres_firmasi TEXT,
    yikama_firmasi TEXT,
    
    -- 7. Teknik Örgü Bilgileri
    makine_tipi TEXT CHECK (makine_tipi IN ('Yuvarlak örgü', 'Düz örgü', 'Raschel', 'Diğer')),
    igne_no TEXT, -- E7, E10, E12, E14
    gauge TEXT, -- 5gg, 7gg, 12gg, 14gg
    orgu_sikligi TEXT CHECK (orgu_sikligi IN ('Gevşek', 'Normal', 'Sıkı')),
    gramaj TEXT, -- 200g/m², 350g/m²
    
    -- 8. Tarih Bilgileri
    siparis_tarihi DATE DEFAULT CURRENT_DATE,
    termin_tarihi DATE,
    
    -- 9. Maliyet Bilgileri (Temel)
    para_birimi TEXT CHECK (para_birimi IN ('TRY', 'USD', 'EUR')) DEFAULT 'TRY',
    tahmini_maliyet DECIMAL(10,2),
    
    -- 10. Teknik Dosyalar (Dosya yolları)
    teknik_cizim_dosyasi TEXT,
    olcu_tablosu_dosyasi TEXT,
    renk_karti_dosyasi TEXT,
    
    -- 11. Özel Talimatlar ve Notlar
    ozel_talimatlar TEXT,
    model_notu TEXT,
    
    -- Durum takibi
    durum TEXT DEFAULT 'Beklemede' CHECK (durum IN ('Beklemede', 'Üretimde', 'Tamamlandı', 'İptal'))
);

-- Maliyet hesaplama tablosu (ayrı sayfa için)
CREATE TABLE IF NOT EXISTS maliyet_hesaplama (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES triko_takip(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- İplik Maliyeti
    iplik_kg_fiyati DECIMAL(10,2),
    kullanilan_iplik_miktari DECIMAL(10,2),
    iplik_maliyeti DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE 
            WHEN iplik_kg_fiyati IS NOT NULL AND kullanilan_iplik_miktari IS NOT NULL 
            THEN iplik_kg_fiyati * kullanilan_iplik_miktari
            ELSE 0
        END
    ) STORED,
    
    -- Örgü Maliyeti
    orgu_suresi DECIMAL(10,2), -- saat
    orgu_fiyati DECIMAL(10,2), -- saat başı
    orgu_maliyeti DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE 
            WHEN orgu_suresi IS NOT NULL AND orgu_fiyati IS NOT NULL 
            THEN orgu_suresi * orgu_fiyati
            ELSE 0
        END
    ) STORED,
    
    -- Diğer Maliyetler
    utu_maliyeti DECIMAL(10,2) DEFAULT 0,
    yikama_maliyeti DECIMAL(10,2) DEFAULT 0,
    boyama_maliyeti DECIMAL(10,2) DEFAULT 0,
    konfeksiyon_maliyeti DECIMAL(10,2) DEFAULT 0,
    aksesuar_maliyeti DECIMAL(10,2) DEFAULT 0,
    fermuar_maliyeti DECIMAL(10,2) DEFAULT 0,
    ilik_dugme_maliyeti DECIMAL(10,2) DEFAULT 0,
    genel_gider DECIMAL(10,2) DEFAULT 0,
    
    -- Toplam Birim Maliyet (Hesaplanan)
    toplam_birim_maliyet DECIMAL(10,2) GENERATED ALWAYS AS (
        COALESCE(iplik_maliyeti, 0) + 
        COALESCE(orgu_maliyeti, 0) + 
        COALESCE(utu_maliyeti, 0) + 
        COALESCE(yikama_maliyeti, 0) + 
        COALESCE(boyama_maliyeti, 0) + 
        COALESCE(konfeksiyon_maliyeti, 0) + 
        COALESCE(aksesuar_maliyeti, 0) + 
        COALESCE(fermuar_maliyeti, 0) + 
        COALESCE(ilik_dugme_maliyeti, 0) + 
        COALESCE(genel_gider, 0)
    ) STORED,
    
    para_birimi TEXT CHECK (para_birimi IN ('TRY', 'USD', 'EUR')) DEFAULT 'TRY',
    
    -- Unique constraint
    UNIQUE(model_id)
);

-- Üretim planı tablosu (ayrı sayfa için)
CREATE TABLE IF NOT EXISTS uretim_plani (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES triko_takip(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Üretim Adımları
    siparis_onay_tarihi DATE,
    iplik_tedarik_baslangic DATE,
    iplik_tedarik_bitis DATE,
    orgu_baslangic DATE,
    orgu_bitis DATE,
    boyama_baslangic DATE,
    boyama_bitis DATE,
    konfeksiyon_baslangic DATE,
    konfeksiyon_bitis DATE,
    kalite_kontrol_tarihi DATE,
    sevkiyat_tarihi DATE,
    
    -- Durum Takibi
    aktif_adim TEXT DEFAULT 'Sipariş Onayı',
    tamamlanan_adimlar TEXT[],
    
    -- Notlar
    uretim_notu TEXT,
    
    -- Unique constraint
    UNIQUE(model_id)
);

-- Teknik dosya tablosu
CREATE TABLE IF NOT EXISTS teknik_dosyalar (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES triko_takip(id) ON DELETE CASCADE,
    dosya_tipi TEXT CHECK (dosya_tipi IN ('Teknik Çizim', 'Ölçü Tablosu', 'Renk Kartı', 'Diğer')),
    dosya_adi TEXT NOT NULL,
    dosya_yolu TEXT NOT NULL,
    dosya_boyutu INTEGER,
    yukleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    yuklenen_kullanici TEXT
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_triko_takip_model_no ON triko_takip(model_no);
CREATE INDEX IF NOT EXISTS idx_triko_takip_marka ON triko_takip(marka);
CREATE INDEX IF NOT EXISTS idx_triko_takip_durum ON triko_takip(durum);
CREATE INDEX IF NOT EXISTS idx_triko_takip_termin ON triko_takip(termin_tarihi);
CREATE INDEX IF NOT EXISTS idx_maliyet_model_id ON maliyet_hesaplama(model_id);
CREATE INDEX IF NOT EXISTS idx_uretim_plani_model_id ON uretim_plani(model_id);
CREATE INDEX IF NOT EXISTS idx_teknik_dosyalar_model_id ON teknik_dosyalar(model_id);

-- Trigger'lar
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_triko_takip_updated_at BEFORE UPDATE ON triko_takip
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maliyet_hesaplama_updated_at BEFORE UPDATE ON maliyet_hesaplama
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_uretim_plani_updated_at BEFORE UPDATE ON uretim_plani
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) - İsteğe bağlı
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE maliyet_hesaplama ENABLE ROW LEVEL SECURITY;
ALTER TABLE uretim_plani ENABLE ROW LEVEL SECURITY;
ALTER TABLE teknik_dosyalar ENABLE ROW LEVEL SECURITY;

-- Basit RLS politikaları (tüm kullanıcılara tam erişim)
CREATE POLICY "Herkes triko_takip tablosuna erişebilir" ON triko_takip FOR ALL USING (true);
CREATE POLICY "Herkes maliyet_hesaplama tablosuna erişebilir" ON maliyet_hesaplama FOR ALL USING (true);
CREATE POLICY "Herkes uretim_plani tablosuna erişebilir" ON uretim_plani FOR ALL USING (true);
CREATE POLICY "Herkes teknik_dosyalar tablosuna erişebilir" ON teknik_dosyalar FOR ALL USING (true);
