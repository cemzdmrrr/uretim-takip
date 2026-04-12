-- TABLO İLİŞKİLERİNİ DÜZELT VE İPLİK STOKLARINI ONAR
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce iplik_stoklari tablosunu kontrol et ve düzelt
CREATE TABLE IF NOT EXISTS iplik_stoklari (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ad TEXT NOT NULL,
  renk TEXT,
  lot_no TEXT,
  miktar NUMERIC(10,2) NOT NULL DEFAULT 0,
  birim TEXT DEFAULT 'kg',
  birim_fiyat NUMERIC(10,2),
  para_birimi TEXT DEFAULT 'TL',
  toplam_deger NUMERIC(10,2),
  tedarikci_id UUID REFERENCES tedarikciler(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. iplik_hareketleri tablosunu düzelt
CREATE TABLE IF NOT EXISTS iplik_hareketleri (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  iplik_id UUID REFERENCES iplik_stoklari(id) ON DELETE CASCADE,
  hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer', 'sayim')),
  miktar NUMERIC(10,2) NOT NULL,
  aciklama TEXT,
  model_id UUID REFERENCES triko_takip(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. iplik_siparisleri tablosunu güncelle (kısmi teslimat desteği için)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_yuzdesi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_yuzdesi NUMERIC(5,2) DEFAULT 0;
    END IF;
END $$;

-- 3. Eksik kolonları ekle
DO $$
BEGIN
    -- iplik_stoklari tablosuna eksik kolonlar
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'tedarikci_id') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN tedarikci_id UUID REFERENCES tedarikciler(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'para_birimi') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN para_birimi TEXT DEFAULT 'TL';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'toplam_deger') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN toplam_deger NUMERIC(10,2);
    END IF;
    
    -- iplik_hareketleri tablosuna eksik kolonlar
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_hareketleri' AND column_name = 'model_id') THEN
        ALTER TABLE iplik_hareketleri ADD COLUMN model_id UUID REFERENCES triko_takip(id);
    END IF;
END $$;

-- 4. RLS politikalarını ayarla
ALTER TABLE iplik_stoklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE iplik_hareketleri ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları sil ve yeniden oluştur
DROP POLICY IF EXISTS allow_all ON iplik_stoklari;
DROP POLICY IF EXISTS allow_all ON iplik_hareketleri;

CREATE POLICY allow_all ON iplik_stoklari FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY allow_all ON iplik_hareketleri FOR ALL USING (true) WITH CHECK (true);

-- 5. İndeksler
CREATE INDEX IF NOT EXISTS idx_iplik_stoklari_tedarikci_id ON iplik_stoklari(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_iplik_hareketleri_iplik_id ON iplik_hareketleri(iplik_id);
CREATE INDEX IF NOT EXISTS idx_iplik_hareketleri_model_id ON iplik_hareketleri(model_id);

-- 6. Trigger'ları güncelle
DROP TRIGGER IF EXISTS update_iplik_stoklari_modtime ON iplik_stoklari;
DROP TRIGGER IF EXISTS update_iplik_hareketleri_modtime ON iplik_hareketleri;

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_iplik_stoklari_modtime 
    BEFORE UPDATE ON iplik_stoklari 
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_iplik_hareketleri_modtime 
    BEFORE UPDATE ON iplik_hareketleri 
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- 7. Test verisi ekle (boş ise)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM iplik_stoklari LIMIT 1) THEN
        INSERT INTO iplik_stoklari (ad, renk, miktar, birim) VALUES 
        ('Pamuk İplik', 'Beyaz', 50.0, 'kg'),
        ('Akrilik İplik', 'Siyah', 25.0, 'kg'),
        ('Yün İplik', 'Gri', 30.0, 'kg');
        
        -- Hareket kayıtları
        INSERT INTO iplik_hareketleri (iplik_id, hareket_tipi, miktar, aciklama)
        SELECT id, 'giris', miktar, 'İlk stok girişi'
        FROM iplik_stoklari;
    END IF;
END $$;

-- 8. Problemli view'i sil
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;

-- Başarı mesajı
SELECT 'İPLİK STOKLARI TABLOLARİ DÜZELTİLDİ!' as sonuc,
       COUNT(*) as stok_sayisi
FROM iplik_stoklari;
