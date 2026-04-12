-- Sevkiyat Kayıtları Tablosu Güncellemesi
-- Bu tablo sevkiyat personelinin yaptığı tüm sevkiyat işlemlerini kaydeder

-- Mevcut tabloyu temizle (varsa)
DROP TABLE IF EXISTS sevkiyat_kayitlari CASCADE;

-- Yeni sevkiyat_kayitlari tablosu
CREATE TABLE IF NOT EXISTS sevkiyat_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Model bilgisi
    model_id UUID NOT NULL REFERENCES triko_takip(id) ON DELETE CASCADE,
    
    -- Kalite kontrol kaynağı (hangi kalite kontrolden geldi)
    kalite_kontrol_id UUID REFERENCES kalite_kontrol_atamalari(id) ON DELETE SET NULL,
    
    -- Sevkiyat personeli
    sevkiyat_personeli_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Adet bilgileri
    alinan_adet INTEGER NOT NULL DEFAULT 0,           -- Kalite kontrolden alınan adet
    sevk_edilen_adet INTEGER NOT NULL DEFAULT 0,      -- Hedef atölyeye gönderilen adet
    kalan_adet INTEGER NOT NULL DEFAULT 0,            -- Henüz sevk edilmemiş adet
    
    -- Hedef bilgisi
    hedef_asama VARCHAR(50),                          -- nakis, yikama, konfeksiyon, utu, ilik_dugme, paketleme, depo
    hedef_tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE SET NULL,
    
    -- Durum
    durum VARCHAR(30) NOT NULL DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'kismen_sevk', 'tamamlandi', 'iptal')),
    
    -- Tarihler
    alis_tarihi TIMESTAMPTZ DEFAULT NOW(),
    sevk_tarihi TIMESTAMPTZ,
    tamamlanma_tarihi TIMESTAMPTZ,
    
    -- Notlar
    notlar TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sevkiyat detayları tablosu (her sevk işlemi için ayrı kayıt)
CREATE TABLE IF NOT EXISTS sevkiyat_detaylari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    sevkiyat_id UUID NOT NULL REFERENCES sevkiyat_kayitlari(id) ON DELETE CASCADE,
    
    -- Sevk bilgileri
    sevk_adet INTEGER NOT NULL CHECK (sevk_adet > 0),
    hedef_asama VARCHAR(50) NOT NULL,
    hedef_tedarikci_id INTEGER REFERENCES tedarikciler(id) ON DELETE SET NULL,
    hedef_atama_id UUID,                              -- Hedef tabloda oluşturulan atama ID'si
    
    -- Personel
    sevk_eden_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Tarih ve notlar
    sevk_tarihi TIMESTAMPTZ DEFAULT NOW(),
    notlar TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_model_id ON sevkiyat_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_durum ON sevkiyat_kayitlari(durum);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_personel ON sevkiyat_kayitlari(sevkiyat_personeli_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_kalite ON sevkiyat_kayitlari(kalite_kontrol_id);

CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_sevkiyat ON sevkiyat_detaylari(sevkiyat_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_detaylari_hedef ON sevkiyat_detaylari(hedef_asama);

-- RLS Politikaları
ALTER TABLE sevkiyat_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE sevkiyat_detaylari ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "sevkiyat_kayitlari_select" ON sevkiyat_kayitlari
    FOR SELECT USING (true);

CREATE POLICY "sevkiyat_detaylari_select" ON sevkiyat_detaylari
    FOR SELECT USING (true);

-- Authenticated kullanıcılar ekleyebilir/güncelleyebilir
CREATE POLICY "sevkiyat_kayitlari_insert" ON sevkiyat_kayitlari
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "sevkiyat_kayitlari_update" ON sevkiyat_kayitlari
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "sevkiyat_detaylari_insert" ON sevkiyat_detaylari
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "sevkiyat_detaylari_update" ON sevkiyat_detaylari
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Yorumlar
COMMENT ON TABLE sevkiyat_kayitlari IS 'Kalite kontrolden geçen ürünlerin sevkiyat bekleyen kayıtları';
COMMENT ON TABLE sevkiyat_detaylari IS 'Her sevk işleminin detay kaydı';
COMMENT ON COLUMN sevkiyat_kayitlari.alinan_adet IS 'Kalite kontrolden alınan toplam adet';
COMMENT ON COLUMN sevkiyat_kayitlari.sevk_edilen_adet IS 'Toplam sevk edilen adet';
COMMENT ON COLUMN sevkiyat_kayitlari.kalan_adet IS 'Henüz sevk edilmemiş adet';
