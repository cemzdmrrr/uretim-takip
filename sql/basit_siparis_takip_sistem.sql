-- BASİT SİPARİŞ TAKİP SİSTEMİ
-- Karmaşık tabloları basitleştir

-- 1. Önce gereksiz tabloları sil
DROP TABLE IF EXISTS iplik_siparis_teslimatlar CASCADE;
DROP TABLE IF EXISTS iplik_siparis_kalemleri CASCADE;
DROP TABLE IF EXISTS iplik_teslimat_kayitlari CASCADE;
DROP VIEW IF EXISTS v_siparis_ozeti CASCADE;

-- 2. iplik_siparisleri tablosunu güçlendir
DO $$
BEGIN
    -- Eksik kolonları ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_edildi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_edildi BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_miktari') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_miktari NUMERIC(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_tarihi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_tarihi DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'lot_no') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN lot_no TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'kalite_durumu') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN kalite_durumu TEXT DEFAULT 'beklemede';
    END IF;
END $$;

-- 3. Basit sipariş takip view'i oluştur
CREATE OR REPLACE VIEW v_siparis_takip AS
SELECT 
    s.*,
    t.sirket as tedarikci_adi,
    t.ad as tedarikci_kisi,
    t.telefon as tedarikci_telefon,
    CASE 
        WHEN s.teslim_edildi = true THEN 'tamamlandi'
        WHEN s.termin_tarihi < CURRENT_DATE AND s.teslim_edildi = false THEN 'gecikti'
        WHEN s.durum = 'onaylandi' THEN 'beklemede'
        ELSE s.durum
    END as takip_durumu,
    CASE 
        WHEN s.miktar > 0 THEN COALESCE(s.teslim_miktari, 0) / s.miktar * 100
        ELSE 0
    END as teslim_yuzdesi
FROM iplik_siparisleri s
LEFT JOIN tedarikciler t ON s.tedarikci_id = t.id;

-- 4. Tamamlanan siparişleri iplik stoklarına aktarma fonksiyonu
CREATE OR REPLACE FUNCTION siparis_stoka_aktar(siparis_id_param UUID)
RETURNS TEXT AS $$
DECLARE
    siparis_kayit RECORD;
    yeni_stok_id UUID;
BEGIN
    -- Siparişi getir
    SELECT * INTO siparis_kayit 
    FROM iplik_siparisleri 
    WHERE id = siparis_id_param AND teslim_edildi = true;
    
    IF NOT FOUND THEN
        RETURN 'Sipariş bulunamadı veya henüz teslim edilmedi';
    END IF;
    
    -- Aynı iplikten stok var mı kontrol et
    SELECT id INTO yeni_stok_id
    FROM iplik_stoklari 
    WHERE ad = siparis_kayit.iplik_adi 
    AND COALESCE(renk, '') = COALESCE(siparis_kayit.renk, '')
    AND COALESCE(lot_no, '') = COALESCE(siparis_kayit.lot_no, '')
    LIMIT 1;
    
    IF yeni_stok_id IS NOT NULL THEN
        -- Mevcut stoku güncelle
        UPDATE iplik_stoklari 
        SET miktar = miktar + siparis_kayit.teslim_miktari,
            updated_at = NOW()
        WHERE id = yeni_stok_id;
    ELSE
        -- Yeni stok oluştur
        INSERT INTO iplik_stoklari (
            ad, renk, lot_no, miktar, birim, 
            birim_fiyat, para_birimi, tedarikci_id
        ) VALUES (
            siparis_kayit.iplik_adi,
            siparis_kayit.renk,
            siparis_kayit.lot_no,
            siparis_kayit.teslim_miktari,
            siparis_kayit.birim,
            siparis_kayit.birim_fiyat,
            siparis_kayit.para_birimi,
            siparis_kayit.tedarikci_id
        ) RETURNING id INTO yeni_stok_id;
    END IF;
    
    -- Hareket kaydı ekle
    INSERT INTO iplik_hareketleri (
        iplik_id, hareket_tipi, miktar, aciklama
    ) VALUES (
        yeni_stok_id, 'giris', siparis_kayit.teslim_miktari,
        'Sipariş teslimi: ' || siparis_kayit.siparis_no
    );
    
    RETURN 'Sipariş başarıyla stoka aktarıldı';
END;
$$ LANGUAGE plpgsql;

-- 5. RLS politikaları
ALTER TABLE iplik_siparisleri ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS allow_all ON iplik_siparisleri;
CREATE POLICY allow_all ON iplik_siparisleri FOR ALL USING (true) WITH CHECK (true);

-- 6. Test verisi ekle (boş ise)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM iplik_siparisleri LIMIT 1) THEN
        -- Örnek sipariş
        INSERT INTO iplik_siparisleri (
            siparis_no, iplik_adi, renk, miktar, birim, 
            termin_tarihi, durum, teslim_edildi, teslim_miktari, teslim_tarihi
        ) VALUES 
        ('SIP-001', 'Pamuk İplik', 'Beyaz', 100.0, 'kg', CURRENT_DATE + 7, 'onaylandi', false, 0, null),
        ('SIP-002', 'Akrilik İplik', 'Siyah', 50.0, 'kg', CURRENT_DATE + 14, 'onaylandi', true, 50.0, CURRENT_DATE),
        ('SIP-003', 'Yün İplik', 'Gri', 75.0, 'kg', CURRENT_DATE - 2, 'onaylandi', false, 0, null);
    END IF;
END $$;

SELECT 'BASİT SİPARİŞ TAKİP SİSTEMİ HAZIR!' as sonuc,
       COUNT(*) as siparis_sayisi
FROM iplik_siparisleri;
