-- Eksik Atama Tablolarını Oluşturma Script'i
-- Bu script eksik olan atama tablolarını oluşturur

-- 1. Nakış atamaları tablosu
CREATE TABLE IF NOT EXISTS nakis_atamalari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id TEXT NOT NULL,
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_firma_id UUID,
    adet INTEGER DEFAULT 0,
    talep_edilen_adet INTEGER DEFAULT 0,
    tamamlanan_adet INTEGER DEFAULT 0,
    durum TEXT DEFAULT 'atandi',
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kabul_tarihi TIMESTAMP WITH TIME ZONE,
    teslim_tarihi TIMESTAMP WITH TIME ZONE,
    son_guncelleme_tarihi TIMESTAMP WITH TIME ZONE
);

-- 2. Yıkama atamaları tablosu
CREATE TABLE IF NOT EXISTS yikama_atamalari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id TEXT NOT NULL,
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_firma_id UUID,
    adet INTEGER DEFAULT 0,
    talep_edilen_adet INTEGER DEFAULT 0,
    tamamlanan_adet INTEGER DEFAULT 0,
    durum TEXT DEFAULT 'atandi',
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kabul_tarihi TIMESTAMP WITH TIME ZONE,
    teslim_tarihi TIMESTAMP WITH TIME ZONE,
    son_guncelleme_tarihi TIMESTAMP WITH TIME ZONE
);

-- 3. İlik düğme atamaları tablosu
CREATE TABLE IF NOT EXISTS ilik_dugme_atamalari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id TEXT NOT NULL,
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_firma_id UUID,
    adet INTEGER DEFAULT 0,
    talep_edilen_adet INTEGER DEFAULT 0,
    tamamlanan_adet INTEGER DEFAULT 0,
    durum TEXT DEFAULT 'atandi',
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kabul_tarihi TIMESTAMP WITH TIME ZONE,
    teslim_tarihi TIMESTAMP WITH TIME ZONE,
    son_guncelleme_tarihi TIMESTAMP WITH TIME ZONE
);

-- 4. Ütü atamaları tablosu
CREATE TABLE IF NOT EXISTS utu_atamalari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id TEXT NOT NULL,
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_firma_id UUID,
    adet INTEGER DEFAULT 0,
    talep_edilen_adet INTEGER DEFAULT 0,
    tamamlanan_adet INTEGER DEFAULT 0,
    durum TEXT DEFAULT 'atandi',
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kabul_tarihi TIMESTAMP WITH TIME ZONE,
    teslim_tarihi TIMESTAMP WITH TIME ZONE,
    son_guncelleme_tarihi TIMESTAMP WITH TIME ZONE
);

-- 5. Triggerlar - updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Nakış atamaları trigger
DROP TRIGGER IF EXISTS update_nakis_atamalari_updated_at ON nakis_atamalari;
CREATE TRIGGER update_nakis_atamalari_updated_at
    BEFORE UPDATE ON nakis_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Yıkama atamaları trigger
DROP TRIGGER IF EXISTS update_yikama_atamalari_updated_at ON yikama_atamalari;
CREATE TRIGGER update_yikama_atamalari_updated_at
    BEFORE UPDATE ON yikama_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- İlik düğme atamaları trigger
DROP TRIGGER IF EXISTS update_ilik_dugme_atamalari_updated_at ON ilik_dugme_atamalari;
CREATE TRIGGER update_ilik_dugme_atamalari_updated_at
    BEFORE UPDATE ON ilik_dugme_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Ütü atamaları trigger
DROP TRIGGER IF EXISTS update_utu_atamalari_updated_at ON utu_atamalari;
CREATE TRIGGER update_utu_atamalari_updated_at
    BEFORE UPDATE ON utu_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6. İndeksler - performans için
CREATE INDEX IF NOT EXISTS idx_nakis_atamalari_model_id ON nakis_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_nakis_atamalari_kullanici ON nakis_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_nakis_atamalari_durum ON nakis_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_model_id ON yikama_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_kullanici ON yikama_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_durum ON yikama_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_model_id ON ilik_dugme_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_kullanici ON ilik_dugme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_durum ON ilik_dugme_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_utu_atamalari_model_id ON utu_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_kullanici ON utu_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_durum ON utu_atamalari(durum);

-- 7. Kontrol - tablolar oluştu mu?
SELECT 'Nakış atamaları: ' || CASE WHEN COUNT(*) > 0 THEN 'OLUŞTU' ELSE 'YOK' END as status
FROM information_schema.tables 
WHERE table_name = 'nakis_atamalari'
UNION ALL
SELECT 'Yıkama atamaları: ' || CASE WHEN COUNT(*) > 0 THEN 'OLUŞTU' ELSE 'YOK' END
FROM information_schema.tables 
WHERE table_name = 'yikama_atamalari'
UNION ALL
SELECT 'İlik düğme atamaları: ' || CASE WHEN COUNT(*) > 0 THEN 'OLUŞTU' ELSE 'YOK' END
FROM information_schema.tables 
WHERE table_name = 'ilik_dugme_atamalari'
UNION ALL
SELECT 'Ütü atamaları: ' || CASE WHEN COUNT(*) > 0 THEN 'OLUŞTU' ELSE 'YOK' END
FROM information_schema.tables 
WHERE table_name = 'utu_atamalari';