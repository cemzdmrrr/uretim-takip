-- Tüm üretim aşamaları için atama tabloları oluştur

-- 1. Konfeksiyon Atamaları
CREATE TABLE IF NOT EXISTS konfeksiyon_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Yıkama Atamaları
CREATE TABLE IF NOT EXISTS yikama_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    yikama_turu TEXT, -- ağır yıkama, hafif yıkama, enzyme yıkama vb.
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Ütü Atamaları
CREATE TABLE IF NOT EXISTS utu_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    utu_tipi TEXT, -- buhar ütü, kuru ütü, pres ütü vb.
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. İlik Düğme Atamaları
CREATE TABLE IF NOT EXISTS ilik_dugme_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    dugme_adedi INTEGER,
    ilik_adedi INTEGER,
    dugme_tipi TEXT,
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Kalite Kontrol Atamaları
CREATE TABLE IF NOT EXISTS kalite_kontrol_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    kontrol_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    kalite_notu INTEGER CHECK (kalite_notu BETWEEN 1 AND 10), -- 1-10 arası kalite puanı
    hatalar TEXT[], -- tespit edilen hatalar array olarak
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Paketleme Atamaları
CREATE TABLE IF NOT EXISTS paketleme_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    paketleme_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
    paket_tipi TEXT, -- standart kutu, özel ambalaj, hediye paketi vb.
    paket_adedi INTEGER,
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Models tablosuna üretim aşaması durumları kolunları ekle
DO $$ 
BEGIN 
    -- Konfeksiyon durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='konfeksiyon_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN konfeksiyon_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (konfeksiyon_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;

    -- Yıkama durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='yikama_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN yikama_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (yikama_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;

    -- Ütü durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='utu_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN utu_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (utu_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;

    -- İlik düğme durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='ilik_dugme_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN ilik_dugme_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (ilik_dugme_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;

    -- Kalite kontrol durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='kalite_kontrol_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN kalite_kontrol_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (kalite_kontrol_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;

    -- Paketleme durumu
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='modeller' AND column_name='paketleme_durumu'
    ) THEN
        ALTER TABLE modeller ADD COLUMN paketleme_durumu TEXT DEFAULT 'bekliyor' 
        CHECK (paketleme_durumu IN ('bekliyor', 'atandi', 'onaylandi', 'uretimde', 'tamamlandi'));
    END IF;
END $$;

-- Güncelleme trigger fonksiyonu (tüm tablolar için ortak)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları ekle
DROP TRIGGER IF EXISTS update_konfeksiyon_atamalari_updated_at ON konfeksiyon_atamalari;
CREATE TRIGGER update_konfeksiyon_atamalari_updated_at
    BEFORE UPDATE ON konfeksiyon_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_yikama_atamalari_updated_at ON yikama_atamalari;
CREATE TRIGGER update_yikama_atamalari_updated_at
    BEFORE UPDATE ON yikama_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_utu_atamalari_updated_at ON utu_atamalari;
CREATE TRIGGER update_utu_atamalari_updated_at
    BEFORE UPDATE ON utu_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ilik_dugme_atamalari_updated_at ON ilik_dugme_atamalari;
CREATE TRIGGER update_ilik_dugme_atamalari_updated_at
    BEFORE UPDATE ON ilik_dugme_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_kalite_kontrol_atamalari_updated_at ON kalite_kontrol_atamalari;
CREATE TRIGGER update_kalite_kontrol_atamalari_updated_at
    BEFORE UPDATE ON kalite_kontrol_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_paketleme_atamalari_updated_at ON paketleme_atamalari;
CREATE TRIGGER update_paketleme_atamalari_updated_at
    BEFORE UPDATE ON paketleme_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_model_id ON konfeksiyon_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_kullanici_id ON konfeksiyon_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_konfeksiyon_atamalari_durum ON konfeksiyon_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_model_id ON yikama_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_kullanici_id ON yikama_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_yikama_atamalari_durum ON yikama_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_utu_atamalari_model_id ON utu_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_kullanici_id ON utu_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_utu_atamalari_durum ON utu_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_model_id ON ilik_dugme_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_kullanici_id ON ilik_dugme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_ilik_dugme_atamalari_durum ON ilik_dugme_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_model_id ON kalite_kontrol_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_kullanici_id ON kalite_kontrol_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_kalite_kontrol_atamalari_durum ON kalite_kontrol_atamalari(durum);

CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_model_id ON paketleme_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_kullanici_id ON paketleme_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_paketleme_atamalari_durum ON paketleme_atamalari(durum);

-- İndeksler models tablosu için
CREATE INDEX IF NOT EXISTS idx_modeller_konfeksiyon_durumu ON modeller(konfeksiyon_durumu);
CREATE INDEX IF NOT EXISTS idx_modeller_yikama_durumu ON modeller(yikama_durumu);
CREATE INDEX IF NOT EXISTS idx_modeller_utu_durumu ON modeller(utu_durumu);
CREATE INDEX IF NOT EXISTS idx_modeller_ilik_dugme_durumu ON modeller(ilik_dugme_durumu);
CREATE INDEX IF NOT EXISTS idx_modeller_kalite_kontrol_durumu ON modeller(kalite_kontrol_durumu);
CREATE INDEX IF NOT EXISTS idx_modeller_paketleme_durumu ON modeller(paketleme_durumu);
