-- Üretim/Sevkiyat Workflow SQL Şeması
-- Bu şema, prototip için geliştirilmiş olan sevkiyat sistemini destekler

-- Atölye türleri ve lokasyonları
CREATE TABLE IF NOT EXISTS atolyeler (
    id SERIAL PRIMARY KEY,
    atolye_adi VARCHAR(100) NOT NULL,
    atolye_turu VARCHAR(50) NOT NULL, -- 'orgu', 'kesim', 'dikim', 'kalite'
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(100),
    kapasitesi INTEGER DEFAULT 100,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Kullanıcı rollerini genişlet
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS atolye_id INTEGER REFERENCES atolyeler(id);
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS yetki_seviyesi INTEGER DEFAULT 1; -- 1: Temel, 2: Orta, 3: Yüksek

-- Sevk talepleri tablosu
CREATE TABLE IF NOT EXISTS sevk_talepleri (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL, -- triko_takip.id UUID olduğu için
    kaynak_atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    hedef_atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    talep_eden_user_id UUID NOT NULL REFERENCES auth.users(id),
    sevk_adeti INTEGER NOT NULL DEFAULT 0,
    
    -- Durum bilgileri
    durum VARCHAR(50) DEFAULT 'bekliyor', -- 'bekliyor', 'onaylandi', 'reddedildi', 'sevkiyatta', 'teslim_edildi'
    onceligi VARCHAR(20) DEFAULT 'normal', -- 'dusuk', 'normal', 'yuksek', 'acil'
    
    -- Kalite kontrol bilgileri
    kalite_kontrol_user_id UUID REFERENCES auth.users(id),
    kalite_kontrol_tarihi TIMESTAMP WITH TIME ZONE,
    kalite_notlari TEXT,
    kalite_onay_durumu BOOLEAN,
    
    -- Sevkiyat bilgileri
    sofor_user_id UUID REFERENCES auth.users(id),
    alinan_tarih TIMESTAMP WITH TIME ZONE,
    sevkiyat_baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tahmini_teslim_tarihi TIMESTAMP WITH TIME ZONE,
    gercek_teslim_tarihi TIMESTAMP WITH TIME ZONE,
    
    -- Teslim alma bilgileri
    teslim_alan_user_id UUID REFERENCES auth.users(id),
    teslim_notlari TEXT,
    hasar_raporu TEXT,
    teslim_onay_durumu BOOLEAN,
    
    -- Ek bilgiler
    aciklama TEXT,
    oncelik_nedeni TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Bildirimler tablosu
CREATE TABLE IF NOT EXISTS bildirimler (
    id SERIAL PRIMARY KEY,
    alici_user_id UUID NOT NULL REFERENCES auth.users(id),
    gonderen_user_id UUID REFERENCES auth.users(id),
    sevk_talebi_id INTEGER REFERENCES sevk_talepleri(id),
    model_id UUID, -- triko_takip.id UUID olduğu için
    
    -- Bildirim detayları
    baslik VARCHAR(200) NOT NULL,
    mesaj TEXT NOT NULL,
    turu VARCHAR(50) NOT NULL, -- 'sevk_talebi', 'kalite_onay', 'sevkiyat', 'teslim', 'red', 'acil'
    oncelik VARCHAR(20) DEFAULT 'normal', -- 'dusuk', 'normal', 'yuksek', 'acil'
    
    -- Durum bilgileri
    okundu BOOLEAN DEFAULT false,
    okunma_tarihi TIMESTAMP WITH TIME ZONE,
    aktif BOOLEAN DEFAULT true,
    
    -- Bildirim eylemi (opsiyonel)
    eylem_gerekli BOOLEAN DEFAULT false,
    eylem_turu VARCHAR(50), -- 'onay_bekliyor', 'teslim_al', 'kalite_kontrol'
    eylem_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Model workflow takibi tablosu
CREATE TABLE IF NOT EXISTS model_workflow_gecmisi (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL, -- triko_takip.id UUID olduğu için
    sevk_talebi_id INTEGER REFERENCES sevk_talepleri(id),
    
    -- Workflow aşama bilgileri
    onceki_durum VARCHAR(50),
    yeni_durum VARCHAR(50) NOT NULL,
    onceki_atolye_id INTEGER REFERENCES atolyeler(id),
    yeni_atolye_id INTEGER REFERENCES atolyeler(id),
    
    -- İşlem yapan kullanıcı
    islem_yapan_user_id UUID NOT NULL REFERENCES auth.users(id),
    islem_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Detaylar
    aciklama TEXT,
    notlar TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Atölye kapasitesi ve iş yükü takibi
CREATE TABLE IF NOT EXISTS atolye_kapasite_takip (
    id SERIAL PRIMARY KEY,
    atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    tarih DATE NOT NULL,
    
    -- Kapasite bilgileri
    toplam_kapasite INTEGER DEFAULT 100,
    kullanilan_kapasite INTEGER DEFAULT 0,
    bekleyen_is_adedi INTEGER DEFAULT 0,
    tamamlanan_is_adedi INTEGER DEFAULT 0,
    
    -- Performans metrikleri
    ortalama_islem_suresi INTERVAL,
    kalite_basari_orani DECIMAL(5,2) DEFAULT 0.00,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    UNIQUE(atolye_id, tarih)
);

-- Triko takip tablosuna workflow alanları ekle (eğer mevcut değilse)
-- NOT: Bu ALTER komutları table structure'a bağlı olarak hata verebilir
-- ALTER TABLE triko_takip ADD COLUMN IF NOT EXISTS mevcut_atolye_id INTEGER REFERENCES atolyeler(id);
-- ALTER TABLE triko_takip ADD COLUMN IF NOT EXISTS workflow_durumu VARCHAR(50) DEFAULT 'atolye_uretemde';
-- ALTER TABLE triko_takip ADD COLUMN IF NOT EXISTS sonraki_atolye_id INTEGER REFERENCES atolyeler(id);
-- ALTER TABLE triko_takip ADD COLUMN IF NOT EXISTS uretim_asamasi INTEGER DEFAULT 1; -- 1: örgü, 2: kesim, 3: dikim, 4: final kalite

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_sevk_talepleri_durum ON sevk_talepleri(durum);
CREATE INDEX IF NOT EXISTS idx_sevk_talepleri_model ON sevk_talepleri(model_id);
CREATE INDEX IF NOT EXISTS idx_sevk_talepleri_kaynak_atolye ON sevk_talepleri(kaynak_atolye_id);
CREATE INDEX IF NOT EXISTS idx_sevk_talepleri_hedef_atolye ON sevk_talepleri(hedef_atolye_id);
CREATE INDEX IF NOT EXISTS idx_sevk_talepleri_tarih ON sevk_talepleri(created_at);

CREATE INDEX IF NOT EXISTS idx_bildirimler_alici ON bildirimler(alici_user_id);
CREATE INDEX IF NOT EXISTS idx_bildirimler_okundu ON bildirimler(okundu);
CREATE INDEX IF NOT EXISTS idx_bildirimler_turu ON bildirimler(turu);
CREATE INDEX IF NOT EXISTS idx_bildirimler_tarih ON bildirimler(created_at);

CREATE INDEX IF NOT EXISTS idx_workflow_gecmisi_model ON model_workflow_gecmisi(model_id);
CREATE INDEX IF NOT EXISTS idx_workflow_gecmisi_tarih ON model_workflow_gecmisi(islem_tarihi);

CREATE INDEX IF NOT EXISTS idx_kapasite_takip_atolye ON atolye_kapasite_takip(atolye_id);
CREATE INDEX IF NOT EXISTS idx_kapasite_takip_tarih ON atolye_kapasite_takip(tarih);

-- NOT: triko_takip table structure belirsiz olduğu için bu indeksler comment'lendi
-- CREATE INDEX IF NOT EXISTS idx_triko_takip_workflow ON triko_takip(workflow_durumu);
-- CREATE INDEX IF NOT EXISTS idx_triko_takip_mevcut_atolye ON triko_takip(mevcut_atolye_id);

-- Trigger'lar
-- Sevk talebi oluşturulduğunda bildirim gönder
CREATE OR REPLACE FUNCTION notify_kalite_kontrol()
RETURNS TRIGGER AS $$
BEGIN
    -- Kalite kontrol personeline bildirim gönder
    INSERT INTO bildirimler (
        alici_user_id, 
        gonderen_user_id, 
        sevk_talebi_id, 
        model_id,
        baslik, 
        mesaj, 
        turu, 
        eylem_gerekli, 
        eylem_turu
    )
    SELECT 
        ur.user_id,
        NEW.talep_eden_user_id,
        NEW.id,
        NEW.model_id,
        'Yeni Kalite Kontrolü Bekliyor',
        'Model #' || NEW.model_id || ' kalite kontrolü için hazır. Sevk adeti: ' || NEW.sevk_adeti,
        'kalite_onay',
        true,
        'kalite_kontrol'
    FROM user_roles ur
    WHERE ur.role = 'kalite_personeli' AND ur.aktif = true;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sevk_talebi_bildirim
    AFTER INSERT ON sevk_talepleri
    FOR EACH ROW
    EXECUTE FUNCTION notify_kalite_kontrol();

-- Kalite onaylandığında sevkiyat personeline bildirim gönder
CREATE OR REPLACE FUNCTION notify_sevkiyat_onay()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer kalite onaylandıysa
    IF NEW.kalite_onay_durumu = true AND OLD.kalite_onay_durumu IS DISTINCT FROM NEW.kalite_onay_durumu THEN
        -- Sevkiyat personeline bildirim gönder
        INSERT INTO bildirimler (
            alici_user_id, 
            gonderen_user_id, 
            sevk_talebi_id, 
            model_id,
            baslik, 
            mesaj, 
            turu, 
            eylem_gerekli, 
            eylem_turu
        )
        SELECT 
            ur.user_id,
            NEW.kalite_kontrol_user_id,
            NEW.id,
            NEW.model_id,
            'Sevkiyat Hazır',
            'Model #' || NEW.model_id || ' kalite kontrolünden geçti, sevkiyat yapılabilir. Adet: ' || NEW.sevk_adeti,
            'sevkiyat',
            true,
            'teslim_al'
        FROM user_roles ur
        WHERE ur.role = 'sevkiyat_personeli' AND ur.aktif = true;
        
        -- Sevk durumunu güncelle
        UPDATE sevk_talepleri SET durum = 'onaylandi' WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_kalite_onay_bildirim
    AFTER UPDATE ON sevk_talepleri
    FOR EACH ROW
    EXECUTE FUNCTION notify_sevkiyat_onay();

-- Model workflow güncellemesi
CREATE OR REPLACE FUNCTION update_model_workflow()
RETURNS TRIGGER AS $$
BEGIN
    -- Workflow geçmişine kaydet
    INSERT INTO model_workflow_gecmisi (
        model_id,
        sevk_talebi_id,
        onceki_durum,
        yeni_durum,
        onceki_atolye_id,
        yeni_atolye_id,
        islem_yapan_user_id,
        aciklama
    ) VALUES (
        NEW.model_id,
        NEW.id,
        OLD.durum,
        NEW.durum,
        OLD.kaynak_atolye_id,
        NEW.hedef_atolye_id,
        NEW.talep_eden_user_id,
        'Sevk talebi durum değişikliği: ' || OLD.durum || ' -> ' || NEW.durum
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_workflow_gecmisi
    AFTER UPDATE ON sevk_talepleri
    FOR EACH ROW
    WHEN (OLD.durum IS DISTINCT FROM NEW.durum)
    EXECUTE FUNCTION update_model_workflow();

-- Örnek veri ekleme
INSERT INTO atolyeler (atolye_adi, atolye_turu, adres, telefon, kapasitesi) VALUES 
('Akar Örgü Atölyesi', 'orgu', 'İstanbul/Sultanbeyli', '0216-123-4567', 150),
('Kesim Merkezi', 'kesim', 'İstanbul/Maltepe', '0216-234-5678', 100),
('Dikim Atölyesi A', 'dikim', 'İstanbul/Kartal', '0216-345-6789', 120),
('Kalite Kontrol Merkezi', 'kalite', 'İstanbul/Pendik', '0216-456-7890', 50)
ON CONFLICT DO NOTHING;

-- Örnek kullanıcı rolleri (mevcut kullanıcılar varsa)
-- Bu kısım gerçek kullanıcı ID'leri ile güncellenmeli
-- INSERT INTO user_roles (user_id, role, atolye_id, yetki_seviyesi) VALUES 
-- ('user-id-1', 'orgu_personeli', (SELECT id FROM atolyeler WHERE atolye_turu = 'orgu' LIMIT 1), 2),
-- ('user-id-2', 'kalite_personeli', (SELECT id FROM atolyeler WHERE atolye_turu = 'kalite' LIMIT 1), 3),
-- ('user-id-3', 'sevkiyat_personeli', NULL, 2);

-- View'lar
-- Aktif sevk talepleri özeti
CREATE OR REPLACE VIEW v_aktif_sevk_talepleri AS
SELECT 
    st.*,
    ka.atolye_adi as kaynak_atolye_adi,
    ha.atolye_adi as hedef_atolye_adi,
    te.email as talep_eden_email,
    kk.email as kalite_kontrol_email,
    so.email as sofor_email,
    ta.email as teslim_alan_email
FROM sevk_talepleri st
JOIN atolyeler ka ON st.kaynak_atolye_id = ka.id
JOIN atolyeler ha ON st.hedef_atolye_id = ha.id
LEFT JOIN auth.users te ON st.talep_eden_user_id = te.id
LEFT JOIN auth.users kk ON st.kalite_kontrol_user_id = kk.id
LEFT JOIN auth.users so ON st.sofor_user_id = so.id
LEFT JOIN auth.users ta ON st.teslim_alan_user_id = ta.id
WHERE st.durum NOT IN ('teslim_edildi', 'iptal_edildi');

-- Bildirim özeti
CREATE OR REPLACE VIEW v_bildirim_ozeti AS
SELECT 
    b.*,
    au.email as alici_email,
    gu.email as gonderen_email,
    st.durum as sevk_durum
FROM bildirimler b
LEFT JOIN auth.users au ON b.alici_user_id = au.id
LEFT JOIN auth.users gu ON b.gonderen_user_id = gu.id
LEFT JOIN sevk_talepleri st ON b.sevk_talebi_id = st.id
WHERE b.aktif = true;

-- Atölye performans raporu
CREATE OR REPLACE VIEW v_atolye_performans AS
SELECT 
    a.id,
    a.atolye_adi,
    a.atolye_turu,
    COUNT(st.id) as toplam_sevk_sayisi,
    COUNT(CASE WHEN st.durum = 'teslim_edildi' THEN 1 END) as tamamlanan_sevk,
    COUNT(CASE WHEN st.kalite_onay_durumu = true THEN 1 END) as onaylanan_kalite,
    COUNT(CASE WHEN st.kalite_onay_durumu = false THEN 1 END) as reddedilen_kalite,
    AVG(EXTRACT(EPOCH FROM (st.gercek_teslim_tarihi - st.created_at))/3600) as ortalama_teslim_suresi_saat
FROM atolyeler a
LEFT JOIN sevk_talepleri st ON a.id = st.kaynak_atolye_id
WHERE a.aktif = true
GROUP BY a.id, a.atolye_adi, a.atolye_turu;

COMMENT ON TABLE sevk_talepleri IS 'Atölyeler arası sevkiyat taleplerini yönetir';
COMMENT ON TABLE bildirimler IS 'Kullanıcılara gönderilen bildirimler';
COMMENT ON TABLE model_workflow_gecmisi IS 'Model workflow sürecinin geçmişini tutar';
COMMENT ON TABLE atolye_kapasite_takip IS 'Atölye kapasitesi ve performans takibi';
COMMENT ON VIEW v_aktif_sevk_talepleri IS 'Aktif sevk taleplerinin detaylı görünümü';
COMMENT ON VIEW v_bildirim_ozeti IS 'Bildirimler için özet görünüm';
COMMENT ON VIEW v_atolye_performans IS 'Atölye performans metrikleri';
