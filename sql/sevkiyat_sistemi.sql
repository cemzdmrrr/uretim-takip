-- Atölyeler tablosu
CREATE TABLE IF NOT EXISTS atolyeler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atolye_adi VARCHAR(255) NOT NULL,
    atolye_tipi VARCHAR(100) NOT NULL, -- 'konfeksiyon', 'yikama', 'ilik_dugme', 'utu'
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(255),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Sevk talepleri tablosu
CREATE TABLE IF NOT EXISTS sevk_talepleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES triko_takip(id),
    gonderici_firma_id UUID NOT NULL, -- Örgü, konfeksiyon vs.
    hedef_atolye_id UUID REFERENCES atolyeler(id),
    sevk_edilen_adet INTEGER NOT NULL,
    durum VARCHAR(50) DEFAULT 'bekliyor', -- 'bekliyor', 'kalite_onay', 'sevk_hazir', 'yolda', 'teslim_edildi', 'kabul_edildi'
    asama VARCHAR(50) NOT NULL, -- 'orgu', 'konfeksiyon', 'yikama', 'ilik_dugme', 'utu'
    hedef_asama VARCHAR(50), -- Bir sonraki aşama
    kalite_notu TEXT,
    kalite_onay_tarihi TIMESTAMP,
    kalite_personel_id UUID,
    sevk_onay_tarihi TIMESTAMP,
    sevkiyat_sofor_id UUID,
    teslim_tarihi TIMESTAMP,
    kabul_tarihi TIMESTAMP,
    kabul_eden_personel_id UUID,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Bildirimler tablosu
CREATE TABLE IF NOT EXISTS bildirimler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kullanici_id UUID NOT NULL,
    baslik VARCHAR(255) NOT NULL,
    mesaj TEXT NOT NULL,
    tip VARCHAR(50) DEFAULT 'bilgi', -- 'bilgi', 'uyari', 'hata', 'basari'
    okundu BOOLEAN DEFAULT false,
    sevk_talebi_id UUID REFERENCES sevk_talepleri(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Kullanıcı rolleri tablosu güncelleme
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS atolye_id UUID REFERENCES atolyeler(id);
ALTER TABLE user_roles ADD COLUMN IF NOT EXISTS yetki_seviyesi VARCHAR(50) DEFAULT 'standart'; -- 'admin', 'kalite', 'sevkiyat', 'atolye_yoneticisi', 'standart'

-- Örnek atölyeler
INSERT INTO atolyeler (atolye_adi, atolye_tipi, adres) VALUES
('Akar Konfeksiyon', 'konfeksiyon', 'İstanbul Avcılar'),
('Modern Yıkama', 'yikama', 'İstanbul Başakşehir'),
('Özgür İlik Düğme', 'ilik_dugme', 'İstanbul Bağcılar'),
('Elite Ütü', 'utu', 'İstanbul Küçükçekmece'),
('Premium Konfeksiyon', 'konfeksiyon', 'İstanbul Esenyurt');
