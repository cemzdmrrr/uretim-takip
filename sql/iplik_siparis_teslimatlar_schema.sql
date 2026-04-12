-- İplik Sipariş Teslimatları Tablosu
CREATE TABLE IF NOT EXISTS iplik_siparis_teslimatlar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    siparis_id UUID NOT NULL REFERENCES iplik_siparisleri(id) ON DELETE CASCADE,
    teslim_kg DECIMAL(10,2) NOT NULL CHECK (teslim_kg > 0),
    iplik_lotu VARCHAR(100),
    gelis_tarihi DATE NOT NULL,
    teslimat_durumu VARCHAR(20) NOT NULL DEFAULT 'tam_teslimat' 
        CHECK (teslimat_durumu IN ('tam_teslimat', 'kismi_teslimat', 'fazla_teslimat')),
    fatura_no VARCHAR(100),
    fatura_tarihi DATE,
    nakliye_firmasi VARCHAR(200),
    kalite_notlari TEXT,
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- İndeks ekleme
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_siparis_id ON iplik_siparis_teslimatlar(siparis_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_gelis_tarihi ON iplik_siparis_teslimatlar(gelis_tarihi);
CREATE INDEX IF NOT EXISTS idx_iplik_siparis_teslimatlar_created_at ON iplik_siparis_teslimatlar(created_at);

-- Updated_at otomatik güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_iplik_siparis_teslimatlar_updated_at 
    BEFORE UPDATE ON iplik_siparis_teslimatlar 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) politikaları
ALTER TABLE iplik_siparis_teslimatlar ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "İplik sipariş teslimatları görüntüleme" ON iplik_siparis_teslimatlar
    FOR SELECT USING (true);

-- Authenticated kullanıcılar ekleyebilir
CREATE POLICY "İplik sipariş teslimatları ekleme" ON iplik_siparis_teslimatlar
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authenticated kullanıcılar güncelleyebilir
CREATE POLICY "İplik sipariş teslimatları güncelleme" ON iplik_siparis_teslimatlar
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Sadece admin silebilir
CREATE POLICY "İplik sipariş teslimatları silme" ON iplik_siparis_teslimatlar
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Yorum ekleme
COMMENT ON TABLE iplik_siparis_teslimatlar IS 'İplik siparişlerinin teslimat kayıtlarını tutar';
COMMENT ON COLUMN iplik_siparis_teslimatlar.siparis_id IS 'Bağlı olduğu sipariş ID''si';
COMMENT ON COLUMN iplik_siparis_teslimatlar.teslim_kg IS 'Teslim edilen miktar (kg)';
COMMENT ON COLUMN iplik_siparis_teslimatlar.iplik_lotu IS 'Gelen ipliğin lot numarası';
COMMENT ON COLUMN iplik_siparis_teslimatlar.gelis_tarihi IS 'İpliğin geldiği tarih';
COMMENT ON COLUMN iplik_siparis_teslimatlar.teslimat_durumu IS 'Teslimat durumu (tam/kısmi/fazla)';
COMMENT ON COLUMN iplik_siparis_teslimatlar.fatura_no IS 'Fatura numarası';
COMMENT ON COLUMN iplik_siparis_teslimatlar.fatura_tarihi IS 'Fatura tarihi';
COMMENT ON COLUMN iplik_siparis_teslimatlar.nakliye_firmasi IS 'Nakliye yapan firma';
COMMENT ON COLUMN iplik_siparis_teslimatlar.kalite_notlari IS 'Kalite kontrol notları';
COMMENT ON COLUMN iplik_siparis_teslimatlar.aciklama IS 'Genel açıklama';
