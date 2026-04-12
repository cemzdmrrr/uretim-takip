-- Mevcut model_kritikleri tablosunu sil ve yeniden oluştur
DROP TABLE IF EXISTS model_kritikleri CASCADE;

-- Model kritikleri tablosu oluşturma (UUID destekli)
CREATE TABLE IF NOT EXISTS model_kritikleri (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL REFERENCES triko_takip(id) ON DELETE CASCADE, -- triko_takip tablosuna referans
    kritik_baslik VARCHAR(200) NOT NULL,
    kritik_aciklama TEXT,
    kritik_turu VARCHAR(50) DEFAULT 'genel', -- 'uretim', 'kalite', 'maliyet', 'teslimat', 'genel'
    oncelik VARCHAR(20) DEFAULT 'orta', -- 'dusuk', 'orta', 'yuksek', 'kritik'
    durum VARCHAR(20) DEFAULT 'aktif', -- 'aktif', 'cozuldu', 'iptal'
    olusturan_kullanici_id UUID REFERENCES auth.users(id),
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cozum_tarihi TIMESTAMP WITH TIME ZONE NULL,
    cozum_aciklamasi TEXT NULL
);

-- Model kritikleri için RLS (Row Level Security) politikaları
ALTER TABLE model_kritikleri ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir (çalışan yetkisi olanlar)
CREATE POLICY "model_kritikleri_select" ON model_kritikleri
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user', 'viewer')
        )
    );

-- Admin ve user ekleme yapabilir
CREATE POLICY "model_kritikleri_insert" ON model_kritikleri
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'user')
        )
    );

-- Admin ve kendi oluşturduğu kayıtları güncelleyebilir
CREATE POLICY "model_kritikleri_update" ON model_kritikleri
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND (role = 'admin' OR (role = 'user' AND model_kritikleri.olusturan_kullanici_id = auth.uid()))
        )
    );

-- Admin silme yapabilir
CREATE POLICY "model_kritikleri_delete" ON model_kritikleri
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Güncelleme tarihi için trigger
CREATE OR REPLACE FUNCTION update_model_kritikleri_guncelleme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER model_kritikleri_guncelleme_tarihi_trigger
    BEFORE UPDATE ON model_kritikleri
    FOR EACH ROW
    EXECUTE FUNCTION update_model_kritikleri_guncelleme_tarihi();

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_model_kritikleri_model_id ON model_kritikleri(model_id);
CREATE INDEX IF NOT EXISTS idx_model_kritikleri_durum ON model_kritikleri(durum);
CREATE INDEX IF NOT EXISTS idx_model_kritikleri_oncelik ON model_kritikleri(oncelik);
CREATE INDEX IF NOT EXISTS idx_model_kritikleri_olusturma_tarihi ON model_kritikleri(olusturma_tarihi);