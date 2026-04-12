-- Dokuma atamaları tablosunu oluştur
CREATE TABLE IF NOT EXISTS dokuma_atamalari (
    id SERIAL PRIMARY KEY,
    model_id INTEGER NOT NULL REFERENCES modeller(id) ON DELETE CASCADE,
    atanan_kullanici_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    durum TEXT DEFAULT 'atandi' CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
    onay_tarihi TIMESTAMP WITH TIME ZONE,
    red_sebebi TEXT,
    uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ı ekle
DROP TRIGGER IF EXISTS update_dokuma_atamalari_updated_at ON dokuma_atamalari;
CREATE TRIGGER update_dokuma_atamalari_updated_at
    BEFORE UPDATE ON dokuma_atamalari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_model_id ON dokuma_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_atanan_kullanici_id ON dokuma_atamalari(atanan_kullanici_id);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_durum ON dokuma_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_dokuma_atamalari_atama_tarihi ON dokuma_atamalari(atama_tarihi);

-- RLS politikaları
ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;

-- Dokuma kullanıcısı sadece kendisine atanmış kayıtları görebilir
CREATE POLICY "Dokuma kullanıcısı kendi atamalarını görebilir" ON dokuma_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'dokuma'
            AND dokuma_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

-- Dokuma kullanıcısı kendi kayıtlarını güncelleyebilir
CREATE POLICY "Dokuma kullanıcısı kendi atamalarını güncelleyebilir" ON dokuma_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'dokuma'
            AND dokuma_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

-- Admin ve yöneticiler tüm atamaları görebilir ve yönetebilir
CREATE POLICY "Admin tüm atamaları yönetebilir" ON dokuma_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- Test verisi ekle (örnek)
-- Bu kısmı gerçek verilerle değiştirin
INSERT INTO dokuma_atamalari (model_id, atanan_kullanici_id, durum, notlar) 
SELECT 
    1 as model_id,  -- Mevcut bir model ID'si
    auth.uid() as atanan_kullanici_id,
    'atandi' as durum,
    'Test ataması' as notlar
WHERE EXISTS (SELECT 1 FROM modeller WHERE id = 1)
  AND EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'dokuma')
ON CONFLICT DO NOTHING;
