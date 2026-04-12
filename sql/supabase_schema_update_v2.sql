-- Enhanced Supabase Schema for Triko/Dokuma Production Management
-- This schema is designed specifically for knitting/weaving production workflows
-- Updated according to detailed prototype requirements

-- Drop existing tables if they exist
DROP TABLE IF EXISTS teknik_dosyalar;
DROP TABLE IF EXISTS maliyet_hesaplama;
DROP TABLE IF EXISTS uretim_plani;
DROP TABLE IF EXISTS triko_takip;

-- Main production tracking table
CREATE TABLE triko_takip (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 1. Temel Model Bilgileri
    marka TEXT NOT NULL,
    item_no TEXT NOT NULL UNIQUE, -- Benzersiz model kodu (örn: TRK001-2025)
    model_adi TEXT, -- Ürün ismi (Basic Crew Neck Sweater)
    sezon TEXT, -- İlkbahar/Yaz, Sonbahar/Kış, Tüm Sezon
    koleksiyon TEXT, -- 2025 Kış, Bahar Koleksiyonu
    
    -- 2. Triko/Dokuma Ürün Detayları
    urun_kategorisi TEXT, -- Kazak, Hırka, Yelek, Elbise, Pantolon
    triko_tipi TEXT, -- Düz örgü, Rib, Kablo, Jakarlı, Fair Isle
    cinsiyet TEXT, -- Erkek, Kadın, Çocuk, Unisex
    yas_grubu TEXT, -- Yetişkin, Çocuk (2-12), Bebek (0-2)
    yaka_tipi TEXT, -- Bisiklet yaka, V yaka, Polo yaka, Balıkçı yaka
    kol_tipi TEXT, -- Uzun kol, Kısa kol, Kolsuz, 3/4 kol
    
    -- 3. İplik ve Materyal Bilgileri
    ana_iplik_turu TEXT, -- Pamuk, Yün, Akrilik, Kaşmir, Alpaka
    iplik_karisimi TEXT, -- %100 Pamuk, %50 Pamuk %50 Akrilik
    iplik_kalinligi TEXT, -- Fine (İnce), Medium (Orta), Chunky (Kalın)
    iplik_markasi TEXT, -- Pamukkale, Kartopu, Nako
    iplik_renk_kodu TEXT, -- Pantone/RAL renk kodları
    iplik_numarasi TEXT, -- Ne 20/1, Ne 30/1
    
    -- 4. Renk ve Desen
    ana_renkler TEXT[], -- Array of colors
    desen_tipi TEXT, -- Düz, Çizgili, Noktalı, Jakarlı desen, Argyle
    desen_detayi TEXT, -- Desen açıklaması veya kodu
    renk_kombinasyonu TEXT, -- Ana renk + yardımcı renkler
    
    -- 5. Beden ve Ölçü Bilgileri
    bedenler JSONB, -- {XS: 30, S: 80, M: 120, L: 100, XL: 70, XXL: 20}
    toplam_adet INTEGER, -- Hesaplanan toplam adet
    gramaj TEXT, -- 200g/m², 350g/m²
    
    -- 6. Üretim Zinciri (Triko Özel)
    orgu_firmasi TEXT, -- Hangi firma örgüyü yapacak
    iplik_tedarikci TEXT, -- İplik nereden gelecek
    boyahane TEXT, -- Boyama işlemi yapılacak yer
    ilik_dugme_metal_aksesuar TEXT, -- İlik düğme ya da metal aksesuar takılacak yer
    konfeksiyon_firmasi TEXT, -- Dikiş ve birleştirme
    utu_pres_firmasi TEXT, -- Finishing işlemleri
    yikama_firmasi TEXT, -- Özel yıkama gerektiriyorsa
    
    -- 7. Teknik Örgü Bilgileri
    makine_tipi TEXT, -- Yuvarlak örgü, Düz örgü, Raschel
    igne_no TEXT, -- E7, E10, E12, E14
    gauge TEXT, -- 5gg, 7gg, 12gg, 14gg
    orgu_sikligi TEXT, -- Gevşek, Normal, Sıkı
    teknik_gramaj TEXT, -- 200g/m², 350g/m²
    
    -- 8. Tarihler ve Durum
    siparis_tarihi DATE,
    termin_tarihi DATE,
    durum TEXT DEFAULT 'Beklemede',
    
    -- 12. Özel Talimatlar
    ozel_talimatlar TEXT, -- Model için özel notlar
    genel_notlar TEXT,
    
    -- Legacy fields for backward compatibility
    renk TEXT,
    urun_cinsi TEXT,
    iplik_cinsi TEXT,
    uretici TEXT,
    adet INTEGER,
    toplam_maliyet DECIMAL,
    kur TEXT DEFAULT 'TRY',
    siparis_notu TEXT
);

-- 9. Maliyet Hesaplama Tablosu (Ayrı sayfa olacak)
CREATE TABLE maliyet_hesaplama (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES triko_takip(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Temel maliyet bilgileri
    marka TEXT,
    model TEXT,
    ip_cinsi TEXT,
    urun_gr DECIMAL, -- Ürün gramı
    iplik_kg_fiyati DECIMAL, -- İplik Kg fiyatı
    iplik_maliyeti DECIMAL, -- İplik Maliyeti: iplik Kg fiyat × kullanılan miktar
    
    -- Üretim maliyetleri
    orgu_suresi DECIMAL, -- Örgü Süresi (saat)
    orgu_fiyati DECIMAL, -- Örgü Fiyatı (saatlik)
    orgu_toplam_maliyet DECIMAL, -- Örgü süresi x örgü fiyatı
    
    -- İşleme maliyetleri
    utu_maliyeti DECIMAL, -- Ütü Maliyeti
    yikama_maliyeti DECIMAL, -- Yıkama maliyeti
    boyama_maliyeti DECIMAL, -- Boyama Maliyeti: Renk başı maliyet
    konfeksiyon_maliyeti DECIMAL, -- Konfeksiyon Maliyeti: İşçilik ücreti
    
    -- Aksesuar maliyetleri
    aksesuar_maliyeti DECIMAL, -- Aksesuar Maliyeti
    fermuar_maliyeti DECIMAL, -- Fermuar maliyeti
    ilik_dugme_maliyeti DECIMAL, -- İlik düğme maliyeti
    
    -- Final hesaplama
    genel_gider DECIMAL, -- Genel gider
    toplam_birim_maliyet DECIMAL, -- Toplam Birim Maliyet: Tüm maliyetlerin toplamı
    para_birimi TEXT DEFAULT 'TRY', -- Para Birimi: TRY, USD, EUR
    
    -- Notlar
    maliyet_notu TEXT
);

-- 8. Üretim Zaman Planı (Ayrı sayfada yapılacak)
CREATE TABLE uretim_plani (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES triko_takip(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Planlama bilgileri
    planlanan_baslangic DATE,
    planlanan_bitis DATE,
    gercek_baslangic DATE,
    gercek_bitis DATE,
    
    -- Üretim aşamaları
    iplik_tedarik_durumu TEXT DEFAULT 'Beklemede',
    iplik_tedarik_tarih DATE,
    orgu_durumu TEXT DEFAULT 'Beklemede',
    orgu_tarih DATE,
    boyama_durumu TEXT DEFAULT 'Beklemede',
    boyama_tarih DATE,
    konfeksiyon_durumu TEXT DEFAULT 'Beklemede',
    konfeksiyon_tarih DATE,
    finishing_durumu TEXT DEFAULT 'Beklemede',
    finishing_tarih DATE,
    
    -- İlerleme takibi
    tamamlanan_miktar INTEGER DEFAULT 0,
    toplam_miktar INTEGER,
    tamamlanma_yuzdesi DECIMAL DEFAULT 0,
    
    -- Notlar
    uretim_notu TEXT
);

-- 11. Teknik Dosyalar
CREATE TABLE teknik_dosyalar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES triko_takip(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Dosya bilgileri
    dosya_adi TEXT NOT NULL,
    dosya_tipi TEXT, -- 'teknik_cizim', 'olcu_tablosu', 'renk_karti'
    dosya_url TEXT,
    dosya_boyutu INTEGER,
    
    -- Açıklama
    aciklama TEXT
);

-- Create indexes for better performance
CREATE INDEX idx_triko_takip_marka ON triko_takip(marka);
CREATE INDEX idx_triko_takip_item_no ON triko_takip(item_no);
CREATE INDEX idx_triko_takip_durum ON triko_takip(durum);
CREATE INDEX idx_triko_takip_termin ON triko_takip(termin_tarihi);
CREATE INDEX idx_triko_takip_sezon ON triko_takip(sezon);
CREATE INDEX idx_triko_takip_kategori ON triko_takip(urun_kategorisi);
CREATE INDEX idx_maliyet_model_id ON maliyet_hesaplama(model_id);
CREATE INDEX idx_uretim_plani_model_id ON uretim_plani(model_id);
CREATE INDEX idx_teknik_dosyalar_model_id ON teknik_dosyalar(model_id);

-- Enable RLS (Row Level Security)
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE maliyet_hesaplama ENABLE ROW LEVEL SECURITY;
ALTER TABLE uretim_plani ENABLE ROW LEVEL SECURITY;
ALTER TABLE teknik_dosyalar ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust according to your auth requirements)
CREATE POLICY "Enable read access for all users" ON triko_takip FOR SELECT USING (true);
CREATE POLICY "Enable insert access for authenticated users" ON triko_takip FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update access for authenticated users" ON triko_takip FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete access for authenticated users" ON triko_takip FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON maliyet_hesaplama FOR SELECT USING (true);
CREATE POLICY "Enable insert access for authenticated users" ON maliyet_hesaplama FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update access for authenticated users" ON maliyet_hesaplama FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete access for authenticated users" ON maliyet_hesaplama FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON uretim_plani FOR SELECT USING (true);
CREATE POLICY "Enable insert access for authenticated users" ON uretim_plani FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update access for authenticated users" ON uretim_plani FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete access for authenticated users" ON uretim_plani FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON teknik_dosyalar FOR SELECT USING (true);
CREATE POLICY "Enable insert access for authenticated users" ON teknik_dosyalar FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update access for authenticated users" ON teknik_dosyalar FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete access for authenticated users" ON teknik_dosyalar FOR DELETE USING (auth.role() = 'authenticated');

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_triko_takip_updated_at BEFORE UPDATE ON triko_takip FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maliyet_hesaplama_updated_at BEFORE UPDATE ON maliyet_hesaplama FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_uretim_plani_updated_at BEFORE UPDATE ON uretim_plani FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
