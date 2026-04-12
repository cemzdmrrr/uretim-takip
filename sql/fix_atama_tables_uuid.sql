-- FİX: Atama tablolarını UUID destekli hale getir
-- AMAÇ: triko_takip tablosu ile uyumlu hale getirmek

-- 1. Önce backup al
CREATE TABLE dokuma_atamalari_backup AS SELECT * FROM dokuma_atamalari;
CREATE TABLE konfeksiyon_atamalari_backup AS SELECT * FROM konfeksiyon_atamalari;

-- 2. Yeni atama tablolarını oluştur (UUID destekli)
DROP TABLE IF EXISTS dokuma_atamalari CASCADE;
CREATE TABLE dokuma_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL, -- UUID'ye değiştirildi
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'baslatildi', 'tamamlandi', 'iptal')),
  notlar TEXT,
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  baslama_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- triko_takip tablosunu referans et
  CONSTRAINT dokuma_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT dokuma_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

-- 3. Diğer atama tablolarını da düzelt
DROP TABLE IF EXISTS konfeksiyon_atamalari CASCADE;
CREATE TABLE konfeksiyon_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL, -- UUID'ye değiştirildi
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT konfeksiyon_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT konfeksiyon_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

-- 4. Tüm atama tablolarını aynı şekilde güncelle
DROP TABLE IF EXISTS yikama_atamalari CASCADE;
CREATE TABLE yikama_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL,
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  yikama_turu TEXT,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT yikama_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT yikama_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

DROP TABLE IF EXISTS utu_atamalari CASCADE;
CREATE TABLE utu_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL,
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  utu_tipi TEXT,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT utu_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT utu_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

DROP TABLE IF EXISTS ilik_dugme_atamalari CASCADE;
CREATE TABLE ilik_dugme_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL,
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  uretim_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  dugme_adedi INTEGER,
  ilik_adedi INTEGER,
  dugme_tipi TEXT,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT ilik_dugme_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT ilik_dugme_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

DROP TABLE IF EXISTS kalite_kontrol_atamalari CASCADE;
CREATE TABLE kalite_kontrol_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL,
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  kontrol_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  kalite_notu INTEGER CHECK (kalite_notu >= 1 AND kalite_notu <= 10),
  hatalar TEXT[],
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT kalite_kontrol_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT kalite_kontrol_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

DROP TABLE IF EXISTS paketleme_atamalari CASCADE;
CREATE TABLE paketleme_atamalari (
  id SERIAL PRIMARY KEY,
  model_id UUID NOT NULL,
  atanan_kullanici_id UUID NOT NULL,
  durum TEXT NOT NULL DEFAULT 'atandi' 
    CHECK (durum IN ('atandi', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi')),
  atama_tarihi TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  onay_tarihi TIMESTAMP WITH TIME ZONE,
  red_sebebi TEXT,
  paketleme_baslangic_tarihi TIMESTAMP WITH TIME ZONE,
  tamamlama_tarihi TIMESTAMP WITH TIME ZONE,
  paket_tipi TEXT,
  paket_adedi INTEGER,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT paketleme_atamalari_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT paketleme_atamalari_atanan_kullanici_id_fkey 
    FOREIGN KEY (atanan_kullanici_id) REFERENCES auth.users(id)
);

-- 5. Indeksler ekle (Performans için)
CREATE INDEX idx_dokuma_atamalari_model_id ON dokuma_atamalari(model_id);
CREATE INDEX idx_dokuma_atamalari_kullanici_id ON dokuma_atamalari(atanan_kullanici_id);
CREATE INDEX idx_dokuma_atamalari_durum ON dokuma_atamalari(durum);

CREATE INDEX idx_konfeksiyon_atamalari_model_id ON konfeksiyon_atamalari(model_id);
CREATE INDEX idx_yikama_atamalari_model_id ON yikama_atamalari(model_id);
CREATE INDEX idx_utu_atamalari_model_id ON utu_atamalari(model_id);
CREATE INDEX idx_ilik_dugme_atamalari_model_id ON ilik_dugme_atamalari(model_id);
CREATE INDEX idx_kalite_kontrol_atamalari_model_id ON kalite_kontrol_atamalari(model_id);
CREATE INDEX idx_paketleme_atamalari_model_id ON paketleme_atamalari(model_id);

-- 6. RLS Politikaları ekle (Row Level Security)
ALTER TABLE dokuma_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;
ALTER TABLE yikama_atamalari ENABLE ROW LEVEL SECURITY;

-- Admin her şeyi görebilir
CREATE POLICY dokuma_admin_policy ON dokuma_atamalari
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'dokuma')
    )
  );

-- Diğer atama politikalarını da benzer şekilde ekle
CREATE POLICY konfeksiyon_admin_policy ON konfeksiyon_atamalari
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'konfeksiyon')
    )
  );

COMMIT;