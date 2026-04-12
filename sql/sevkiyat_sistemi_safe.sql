-- Sevkiyat Sistemi - Güvenli Kurulum Versiyonu
-- Bu dosya mevcut tablo yapısından bağımsız çalışacak şekilde tasarlandı

-- 1. Atölye türleri ve lokasyonları
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

-- 2. Kullanıcı rollerini genişlet (eğer mevcut değilse)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_roles' AND column_name='atolye_id') THEN
        ALTER TABLE user_roles ADD COLUMN atolye_id INTEGER REFERENCES atolyeler(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_roles' AND column_name='yetki_seviyesi') THEN
        ALTER TABLE user_roles ADD COLUMN yetki_seviyesi INTEGER DEFAULT 1;
    END IF;
END $$;

-- 3. Sevk talepleri tablosu - model_id UUID olarak tanımlandı
CREATE TABLE IF NOT EXISTS sevk_talepleri (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL, -- triko_takip.id UUID formatında
    kaynak_atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    hedef_atolye_id INTEGER NOT NULL REFERENCES atolyeler(id),
    talep_eden_user_id UUID NOT NULL,
    sevk_adeti INTEGER NOT NULL DEFAULT 0,
    
    -- Durum bilgileri
    durum VARCHAR(50) DEFAULT 'bekliyor',
    onceligi VARCHAR(20) DEFAULT 'normal',
    
    -- Kalite kontrol bilgileri
    kalite_kontrol_user_id UUID,
    kalite_kontrol_tarihi TIMESTAMP WITH TIME ZONE,
    kalite_notlari TEXT,
    kalite_onay_durumu BOOLEAN,
    
    -- Sevkiyat bilgileri
    sofor_user_id UUID,
    alinan_tarih TIMESTAMP WITH TIME ZONE,
    sevkiyat_baslama_tarihi TIMESTAMP WITH TIME ZONE,
    tahmini_teslim_tarihi TIMESTAMP WITH TIME ZONE,
    gercek_teslim_tarihi TIMESTAMP WITH TIME ZONE,
    
    -- Teslim alma bilgileri
    teslim_alan_user_id UUID,
    teslim_notlari TEXT,
    hasar_raporu TEXT,
    teslim_onay_durumu BOOLEAN,
    
    -- Ek bilgiler
    aciklama TEXT,
    oncelik_nedeni TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Bildirimler tablosu
CREATE TABLE IF NOT EXISTS bildirimler (
    id SERIAL PRIMARY KEY,
    alici_user_id UUID NOT NULL,
    gonderen_user_id UUID,
    sevk_talebi_id INTEGER REFERENCES sevk_talepleri(id),
    model_id UUID,
    
    -- Bildirim detayları
    baslik VARCHAR(200) NOT NULL,
    mesaj TEXT NOT NULL,
    turu VARCHAR(50) NOT NULL,
    oncelik VARCHAR(20) DEFAULT 'normal',
    
    -- Durum bilgileri
    okundu BOOLEAN DEFAULT false,
    okunma_tarihi TIMESTAMP WITH TIME ZONE,
    aktif BOOLEAN DEFAULT true,
    
    -- Bildirim eylemi (opsiyonel)
    eylem_gerekli BOOLEAN DEFAULT false,
    eylem_turu VARCHAR(50),
    eylem_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Model workflow takibi tablosu
CREATE TABLE IF NOT EXISTS model_workflow_gecmisi (
    id SERIAL PRIMARY KEY,
    model_id UUID NOT NULL,
    sevk_talebi_id INTEGER REFERENCES sevk_talepleri(id),
    
    -- Workflow aşama bilgileri
    onceki_durum VARCHAR(50),
    yeni_durum VARCHAR(50) NOT NULL,
    onceki_atolye_id INTEGER REFERENCES atolyeler(id),
    yeni_atolye_id INTEGER REFERENCES atolyeler(id),
    
    -- İşlem yapan kullanıcı
    islem_yapan_user_id UUID NOT NULL,
    islem_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Detaylar
    aciklama TEXT,
    notlar TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Atölye kapasitesi ve iş yükü takibi
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

-- 7. İndeksler
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

-- 8. Trigger'lar (Güvenli Versiyon)
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
    WHERE ur.role = 'kalite_personeli' AND (ur.aktif IS NULL OR ur.aktif = true);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sevk_talebi_bildirim ON sevk_talepleri;
CREATE TRIGGER trigger_sevk_talebi_bildirim
    AFTER INSERT ON sevk_talepleri
    FOR EACH ROW
    EXECUTE FUNCTION notify_kalite_kontrol();

-- Kalite onaylandığında sevkiyat personeline bildirim gönder
CREATE OR REPLACE FUNCTION notify_sevkiyat_onay()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer kalite onaylandıysa
    IF NEW.kalite_onay_durumu = true AND (OLD.kalite_onay_durumu IS NULL OR OLD.kalite_onay_durumu IS DISTINCT FROM NEW.kalite_onay_durumu) THEN
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
        WHERE ur.role = 'sevkiyat_personeli' AND (ur.aktif IS NULL OR ur.aktif = true);
        
        -- Sevk durumunu güncelle
        UPDATE sevk_talepleri SET durum = 'onaylandi' WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_kalite_onay_bildirim ON sevk_talepleri;
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
        COALESCE(NEW.kalite_kontrol_user_id, NEW.sofor_user_id, NEW.teslim_alan_user_id, NEW.talep_eden_user_id),
        'Sevk talebi durum değişikliği: ' || COALESCE(OLD.durum, 'yeni') || ' -> ' || NEW.durum
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_workflow_gecmisi ON sevk_talepleri;
CREATE TRIGGER trigger_workflow_gecmisi
    AFTER UPDATE ON sevk_talepleri
    FOR EACH ROW
    WHEN (OLD.durum IS DISTINCT FROM NEW.durum)
    EXECUTE FUNCTION update_model_workflow();

-- 9. Örnek veri ekleme
INSERT INTO atolyeler (atolye_adi, atolye_turu, adres, telefon, kapasitesi) VALUES 
('Akar Örgü Atölyesi', 'orgu', 'İstanbul/Sultanbeyli', '0216-123-4567', 150),
('Kesim Merkezi', 'kesim', 'İstanbul/Maltepe', '0216-234-5678', 100),
('Dikim Atölyesi A', 'dikim', 'İstanbul/Kartal', '0216-345-6789', 120),
('Kalite Kontrol Merkezi', 'kalite', 'İstanbul/Pendik', '0216-456-7890', 50)
ON CONFLICT DO NOTHING;

-- 10. View'lar (Basitleştirilmiş)
CREATE OR REPLACE VIEW v_aktif_sevk_talepleri AS
SELECT 
    st.*,
    ka.atolye_adi as kaynak_atolye_adi,
    ha.atolye_adi as hedef_atolye_adi
FROM sevk_talepleri st
JOIN atolyeler ka ON st.kaynak_atolye_id = ka.id
JOIN atolyeler ha ON st.hedef_atolye_id = ha.id
WHERE st.durum NOT IN ('teslim_edildi', 'iptal_edildi');

CREATE OR REPLACE VIEW v_bildirim_ozeti AS
SELECT 
    b.*,
    st.durum as sevk_durum
FROM bildirimler b
LEFT JOIN sevk_talepleri st ON b.sevk_talebi_id = st.id
WHERE b.aktif = true;

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

-- 11. Tablolar hakkında açıklamalar
COMMENT ON TABLE atolyeler IS 'Üretim atölyelerinin bilgilerini tutar';
COMMENT ON TABLE sevk_talepleri IS 'Atölyeler arası sevkiyat taleplerini yönetir';
COMMENT ON TABLE bildirimler IS 'Kullanıcılara gönderilen bildirimler';
COMMENT ON TABLE model_workflow_gecmisi IS 'Model workflow sürecinin geçmişini tutar';
COMMENT ON TABLE atolye_kapasite_takip IS 'Atölye kapasitesi ve performans takibi';

-- 12. Kurulum başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '=== SEVKİYAT SİSTEMİ KURULUMU TAMAMLANDI ===';
    RAISE NOTICE 'Toplam % tablo oluşturuldu:', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('atolyeler', 'sevk_talepleri', 'bildirimler', 'model_workflow_gecmisi', 'atolye_kapasite_takip'));
    RAISE NOTICE 'Örnek atölye sayısı: %', (SELECT COUNT(*) FROM atolyeler);
    RAISE NOTICE 'Sistem kullanıma hazır!';
END $$;
