-- Üretim Workflow Sistemi SQL Tabloları
-- Bu dosya yeni üretim workflow sistemini destekleyen tabloları oluşturur

-- 1. Üretim Kayıtları Tablosu
CREATE TABLE IF NOT EXISTS uretim_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES triko_takip(id) ON DELETE CASCADE,
    asama TEXT NOT NULL CHECK (asama IN ('orgu', 'konfeksiyon', 'utu')),
    firma_id INTEGER REFERENCES atolyeler(id),
    tamamlanan_adet INTEGER NOT NULL CHECK (tamamlanan_adet > 0),
    tamamlanma_tarihi TIMESTAMPTZ NOT NULL,
    uretici_user_id UUID REFERENCES auth.users(id),
    durum TEXT NOT NULL DEFAULT 'kalite_bekliyor' CHECK (durum IN (
        'kalite_bekliyor', 
        'kalite_reddedildi', 
        'sevkiyat_bekliyor', 
        'sevk_edildi'
    )),
    
    -- Kalite kontrol alanları
    kalite_onay_durumu BOOLEAN,
    kalite_kontrol_user_id UUID REFERENCES auth.users(id),
    kalite_kontrol_tarihi TIMESTAMPTZ,
    kalite_notlari TEXT,
    
    -- Sevkiyat alanları
    sevkiyat_tarihi TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Sevkiyat Kayıtları Tablosu
CREATE TABLE IF NOT EXISTS sevkiyat_kayitlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uretim_kaydi_id UUID NOT NULL REFERENCES uretim_kayitlari(id) ON DELETE CASCADE,
    sevkiyat_personeli_id UUID NOT NULL REFERENCES auth.users(id),
    alinan_adet INTEGER NOT NULL CHECK (alinan_adet > 0),
    hedef_atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    sevkiyat_tarihi TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notlar TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Bildirimler Tablosu
CREATE TABLE IF NOT EXISTS bildirimler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    baslik TEXT NOT NULL,
    mesaj TEXT NOT NULL,
    tip TEXT NOT NULL CHECK (tip IN ('kalite_onay', 'sevkiyat_hazir', 'genel')),
    model_id UUID REFERENCES triko_takip(id) ON DELETE CASCADE,
    uretim_kaydi_id UUID REFERENCES uretim_kayitlari(id) ON DELETE CASCADE,
    asama TEXT CHECK (asama IN ('orgu', 'konfeksiyon', 'utu')),
    okundu BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexler
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_model_id ON uretim_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_asama ON uretim_kayitlari(asama);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_durum ON uretim_kayitlari(durum);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_firma_id ON uretim_kayitlari(firma_id);

CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_uretim_kaydi ON sevkiyat_kayitlari(uretim_kaydi_id);
CREATE INDEX IF NOT EXISTS idx_sevkiyat_kayitlari_hedef_atolye ON sevkiyat_kayitlari(hedef_atolye_id);

CREATE INDEX IF NOT EXISTS idx_bildirimler_user_id ON bildirimler(user_id);
CREATE INDEX IF NOT EXISTS idx_bildirimler_okundu ON bildirimler(okundu);
CREATE INDEX IF NOT EXISTS idx_bildirimler_model_id ON bildirimler(model_id);

-- Updated_at trigger'ı
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_uretim_kayitlari_updated_at 
    BEFORE UPDATE ON uretim_kayitlari 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) Politikaları
ALTER TABLE uretim_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE sevkiyat_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE bildirimler ENABLE ROW LEVEL SECURITY;

-- Üretim kayıtları için RLS
CREATE POLICY "Kullanıcılar kendi firma kayıtlarını görebilir" ON uretim_kayitlari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND (
                role IN ('admin') OR 
                (role IN ('user', 'orgu', 'konfeksiyon', 'utu', 'orgu_personeli', 'konfeksiyon_personeli', 'utu_personeli') AND atolye_id = firma_id) OR
                role IN ('kalite', 'sevkiyat', 'kalite_personeli', 'sevkiyat_personeli')
            )
        )
    );

CREATE POLICY "Firma personeli kendi kayıtlarını ekleyebilir" ON uretim_kayitlari
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND atolye_id = firma_id
            AND role IN ('admin', 'user', 'orgu', 'konfeksiyon', 'utu', 'orgu_personeli', 'konfeksiyon_personeli', 'utu_personeli')
        )
    );

CREATE POLICY "Kalite ve sevkiyat personeli kayıtları güncelleyebilir" ON uretim_kayitlari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'kalite', 'sevkiyat', 'kalite_personeli', 'sevkiyat_personeli')
        )
    );

-- Sevkiyat kayıtları için RLS
CREATE POLICY "Sevkiyat kayıtlarını yetkili personel görebilir" ON sevkiyat_kayitlari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'sevkiyat', 'sevkiyat_personeli')
        )
    );

CREATE POLICY "Sevkiyat personeli kayıt ekleyebilir" ON sevkiyat_kayitlari
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'sevkiyat', 'sevkiyat_personeli')
        )
    );

-- Bildirimler için RLS
CREATE POLICY "Kullanıcılar kendi bildirimlerini görebilir" ON bildirimler
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Sistem bildirimleri ekleyebilir" ON bildirimler
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Kullanıcılar kendi bildirimlerini güncelleyebilir" ON bildirimler
    FOR UPDATE USING (user_id = auth.uid());

-- Trigger fonksiyonları
CREATE OR REPLACE FUNCTION notify_quality_control()
RETURNS TRIGGER AS $$
DECLARE
    quality_users UUID[];
    user_id UUID;
    firma_name TEXT;
BEGIN
    -- Kalite personellerini bul (admin ve kalite rolleri)
    SELECT ARRAY(
        SELECT ur.user_id 
        FROM user_roles ur 
        WHERE ur.role IN ('admin', 'kalite', 'kalite_personeli')
    ) INTO quality_users;
    
    -- Firma adını al
    SELECT atolye_adi INTO firma_name
    FROM atolyeler 
    WHERE id = NEW.firma_id;
    
    -- Her kalite personeeline bildirim gönder
    FOREACH user_id IN ARRAY quality_users
    LOOP
        INSERT INTO bildirimler (
            user_id, 
            baslik, 
            mesaj, 
            tip, 
            model_id, 
            uretim_kaydi_id,
            asama
        ) VALUES (
            user_id,
            NEW.asama || ' Üretim Tamamlandı',
            COALESCE(firma_name, 'Bilinmeyen Firma') || ' firması ' || NEW.tamamlanan_adet || ' adet ürünü sevke hazırladı.',
            'kalite_onay',
            NEW.model_id,
            NEW.id,
            NEW.asama
        );
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_shipping_personnel()
RETURNS TRIGGER AS $$
DECLARE
    shipping_users UUID[];
    user_id UUID;
    firma_name TEXT;
BEGIN
    -- Sadece kalite onaylandığında çalış
    IF NEW.durum = 'sevkiyat_bekliyor' AND OLD.durum = 'kalite_bekliyor' THEN
        -- Sevkiyat personellerini bul (admin ve sevkiyat rolleri)
        SELECT ARRAY(
            SELECT ur.user_id 
            FROM user_roles ur 
            WHERE ur.role IN ('admin', 'sevkiyat', 'sevkiyat_personeli')
        ) INTO shipping_users;
        
        -- Firma adını al
        SELECT atolye_adi INTO firma_name
        FROM atolyeler 
        WHERE id = NEW.firma_id;
        
        -- Her sevkiyat personeeline bildirim gönder
        FOREACH user_id IN ARRAY shipping_users
        LOOP
            INSERT INTO bildirimler (
                user_id, 
                baslik, 
                mesaj, 
                tip, 
                model_id, 
                uretim_kaydi_id,
                asama
            ) VALUES (
                user_id,
                NEW.asama || ' Sevkiyat Hazır',
                COALESCE(firma_name, 'Bilinmeyen Firma') || ' firmasında ' || NEW.tamamlanan_adet || ' adet ürün sevk edilebilir.',
                'sevkiyat_hazir',
                NEW.model_id,
                NEW.id,
                NEW.asama
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur
CREATE TRIGGER trigger_notify_quality_control
    AFTER INSERT ON uretim_kayitlari
    FOR EACH ROW
    EXECUTE FUNCTION notify_quality_control();

CREATE TRIGGER trigger_notify_shipping_personnel
    AFTER UPDATE ON uretim_kayitlari
    FOR EACH ROW
    EXECUTE FUNCTION notify_shipping_personnel();

-- View'lar
CREATE OR REPLACE VIEW uretim_kayitlari_detay AS
SELECT 
    uk.*,
    a.atolye_adi as firma_adi,
    tt.marka,
    tt.item_no,
    u_uretici.email as uretici_email,
    u_kalite.email as kalite_kontrol_email,
    sk.alinan_adet as sevk_edilen_adet,
    sk.sevkiyat_tarihi as gercek_sevkiyat_tarihi,
    hedef_atolye.atolye_adi as hedef_atolye_adi
FROM uretim_kayitlari uk
LEFT JOIN atolyeler a ON uk.firma_id = a.id
LEFT JOIN triko_takip tt ON uk.model_id = tt.id
LEFT JOIN auth.users u_uretici ON uk.uretici_user_id = u_uretici.id
LEFT JOIN auth.users u_kalite ON uk.kalite_kontrol_user_id = u_kalite.id
LEFT JOIN sevkiyat_kayitlari sk ON uk.id = sk.uretim_kaydi_id
LEFT JOIN atolyeler hedef_atolye ON sk.hedef_atolye_id = hedef_atolye.id;

-- Bildirimler view'i
CREATE OR REPLACE VIEW bildirimler_detay AS
SELECT 
    b.*,
    tt.marka,
    tt.item_no,
    uk.tamamlanan_adet,
    a.atolye_adi as firma_adi
FROM bildirimler b
LEFT JOIN triko_takip tt ON b.model_id = tt.id
LEFT JOIN uretim_kayitlari uk ON b.uretim_kaydi_id = uk.id
LEFT JOIN atolyeler a ON uk.firma_id = a.id;

COMMENT ON TABLE uretim_kayitlari IS 'Firma üretim tamamlama kayıtları - kalite ve sevkiyat süreçleri dahil';
COMMENT ON TABLE sevkiyat_kayitlari IS 'Sevkiyat personeli tarafından yapılan teslimat kayıtları';
COMMENT ON TABLE bildirimler IS 'Sistem bildirimleri - kalite onay ve sevkiyat bildirimleri';
