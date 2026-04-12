-- Ürün Depo Tablosu
-- Üretimden artan ve kalite kontrolünü geçen ürünleri depolama

CREATE TABLE IF NOT EXISTS urun_depo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- İlişkiler
    model_id UUID NOT NULL,
    
    -- Ürün Bilgileri
    kalite_tipi VARCHAR(50) NOT NULL CHECK (kalite_tipi IN ('1. Kalite', '2. & 3. Kalite')),
    adet INT NOT NULL CHECK (adet > 0),
    
    -- Açıklama
    aciklama TEXT,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Key
    CONSTRAINT fk_model FOREIGN KEY (model_id) REFERENCES triko_takip(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_urun_depo_kalite ON urun_depo(kalite_tipi);
CREATE INDEX idx_urun_depo_model ON urun_depo(model_id);
CREATE INDEX idx_urun_depo_created ON urun_depo(created_at DESC);

-- RLS Politikaları
ALTER TABLE urun_depo ENABLE ROW LEVEL SECURITY;

-- Admin: Tüm ürünleri görebilir ve yönetebilir
CREATE POLICY urun_depo_admin_all ON urun_depo
    FOR ALL
    USING (
        (SELECT role FROM user_roles WHERE user_id = auth.uid() LIMIT 1) = 'admin'
    );

-- Depo Personeli: Kendi ekledikleri ve tüm ürünleri görebilir
CREATE POLICY urun_depo_depo_personel_select ON urun_depo
    FOR SELECT
    USING (
        (SELECT role FROM user_roles WHERE user_id = auth.uid() LIMIT 1) IN ('depo', 'depocu')
    );

CREATE POLICY urun_depo_depo_personel_insert ON urun_depo
    FOR INSERT
    WITH CHECK (
        (SELECT role FROM user_roles WHERE user_id = auth.uid() LIMIT 1) IN ('depo', 'depocu')
    );

CREATE POLICY urun_depo_depo_personel_delete ON urun_depo
    FOR DELETE
    USING (
        (SELECT role FROM user_roles WHERE user_id = auth.uid() LIMIT 1) IN ('depo', 'depocu')
    );

-- Diğer roller: Sadece görüntüleyebilir
CREATE POLICY urun_depo_others_select ON urun_depo
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Tabloyu test et
SELECT 
    'urun_depo' as tablo,
    COUNT(*) as toplam_urun,
    COUNT(DISTINCT kalite_tipi) as kalite_cesitleri
FROM urun_depo;

-- Kalite tipi dağılımı
SELECT 
    kalite_tipi,
    COUNT(*) as urun_sayisi,
    SUM(adet) as toplam_adet
FROM urun_depo
GROUP BY kalite_tipi
ORDER BY kalite_tipi;
