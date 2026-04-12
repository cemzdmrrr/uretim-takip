-- İPLİK SİPARİŞ TABLOSUNU GÜNCELLE
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. iplik_siparisleri tablosuna yeni kolonlar ekle
DO $$
BEGIN
    -- Marka kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'marka') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN marka TEXT;
    END IF;
    
    -- Örgü firması ID kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'orgu_firmasi_id') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN orgu_firmasi_id UUID REFERENCES tedarikciler(id);
    END IF;
    
    -- Teslim yüzdesi kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_yuzdesi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_yuzdesi NUMERIC(5,2) DEFAULT 0;
    END IF;
    
    -- Kalite durumu kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'kalite_durumu') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN kalite_durumu TEXT DEFAULT 'onaylandi';
    END IF;
END $$;

-- 2. İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_orgu_firmasi_id ON iplik_siparisleri(orgu_firmasi_id);
CREATE INDEX IF NOT EXISTS idx_iplik_siparisleri_marka ON iplik_siparisleri(marka);

-- 3. Sipariş takip view'ini güncelle
DROP VIEW IF EXISTS v_siparis_takip CASCADE;

CREATE VIEW v_siparis_takip AS
SELECT 
    s.id,
    s.siparis_no,
    s.marka,
    s.iplik_adi,
    s.renk,
    s.miktar,
    s.birim,
    s.teslim_miktari,
    s.teslim_yuzdesi,
    s.birim_fiyat,
    s.para_birimi,
    s.toplam_tutar,
    s.termin_tarihi,
    s.teslim_tarihi,
    s.lot_no,
    s.kalite_durumu,
    s.siparis_tarihi,
    s.durum,
    s.aciklama,
    s.teslim_edildi,
    s.created_at,
    s.updated_at,
    
    -- Tedarikçi bilgileri
    t.sirket as tedarikci_adi,
    t.telefon as tedarikci_telefon,
    s.tedarikci_id,
    
    -- Örgü firması bilgileri
    o.sirket as orgu_firmasi_adi,
    o.telefon as orgu_firmasi_telefon,
    s.orgu_firmasi_id,
    
    -- Takip durumu hesaplama
    CASE 
        WHEN s.teslim_edildi = true THEN 'tamamlandi'
        WHEN s.termin_tarihi IS NOT NULL AND s.termin_tarihi < CURRENT_DATE AND s.teslim_edildi != true THEN 'gecikti'
        ELSE 'beklemede'
    END as takip_durumu
    
FROM iplik_siparisleri s
LEFT JOIN tedarikciler t ON s.tedarikci_id = t.id
LEFT JOIN tedarikciler o ON s.orgu_firmasi_id = o.id
ORDER BY s.created_at DESC;

-- 4. RLS politikalarını güncelle
ALTER TABLE iplik_siparisleri ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları sil ve yeniden oluştur
DROP POLICY IF EXISTS allow_all ON iplik_siparisleri;
CREATE POLICY allow_all ON iplik_siparisleri FOR ALL USING (true) WITH CHECK (true);

-- 5. View için RLS politikası
DROP POLICY IF EXISTS allow_all_view ON v_siparis_takip;

-- Başarı mesajı
SELECT 'İPLİK SİPARİŞ TABLOSU GÜNCELLENDİ!' as sonuc,
       COUNT(*) as siparis_sayisi
FROM iplik_siparisleri;
