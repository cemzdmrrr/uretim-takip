-- MÜŞTERI-SİPARİŞ ENTEGRASYONU İÇİN VERİTABANI GÜNCELLEMESI
-- Bu script mevcut triko_takip tablosuna müşteri alanı ekler

-- 1. triko_takip tablosuna müşteri_id kolonu ekle
ALTER TABLE triko_takip 
ADD COLUMN musteri_id INTEGER REFERENCES musteriler(id);

-- 2. Müşteri_id için index oluştur (performans için)
CREATE INDEX IF NOT EXISTS idx_triko_takip_musteri_id ON triko_takip(musteri_id);

-- 3. Sipariş durumu ve tarihleri için ek kolonlar (isteğe bağlı)
ALTER TABLE triko_takip 
ADD COLUMN siparis_tarihi DATE DEFAULT CURRENT_DATE,
ADD COLUMN siparis_notu TEXT,
ADD COLUMN toplam_maliyet DECIMAL(10,2),
ADD COLUMN kur VARCHAR(3) DEFAULT 'TRY';

-- 4. Müşteri raporları için view oluştur
CREATE OR REPLACE VIEW musteri_siparis_ozet AS
SELECT 
    m.id as musteri_id,
    m.ad,
    m.soyad,
    m.sirket,
    m.musteri_tipi,
    COUNT(t.id) as toplam_siparis,
    COUNT(CASE WHEN t.tamamlandi = true THEN 1 END) as tamamlanan_siparis,
    COUNT(CASE WHEN t.tamamlandi = false OR t.tamamlandi IS NULL THEN 1 END) as devam_eden_siparis,
    SUM(CASE WHEN t.toplam_maliyet IS NOT NULL THEN t.toplam_maliyet ELSE 0 END) as toplam_ciro,
    MIN(t.siparis_tarihi) as ilk_siparis_tarihi,
    MAX(t.siparis_tarihi) as son_siparis_tarihi
FROM musteriler m
LEFT JOIN triko_takip t ON m.id = t.musteri_id
GROUP BY m.id, m.ad, m.soyad, m.sirket, m.musteri_tipi;

-- 5. RLS (Row Level Security) politikaları güncelle
DROP POLICY IF EXISTS "Enable read access for all users" ON triko_takip;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON triko_takip;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON triko_takip;
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON triko_takip;

CREATE POLICY "Enable read access for all users" ON triko_takip FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON triko_takip FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Enable update for authenticated users only" ON triko_takip FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Enable delete for authenticated users only" ON triko_takip FOR DELETE USING (auth.uid() IS NOT NULL);

-- 6. View için RLS etkinleştir
ALTER VIEW musteri_siparis_ozet SET (security_invoker = true);

-- 7. Müşteri silme işleminde siparişleri korumak için güncelleme
-- Müşteri silindiğinde sipariş kayıtları korunur, sadece müşteri_id NULL yapılır
CREATE OR REPLACE FUNCTION handle_customer_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Müşteri silindiğinde, siparişlerdeki müşteri_id'yi NULL yap
    UPDATE triko_takip 
    SET musteri_id = NULL 
    WHERE musteri_id = OLD.id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_customer_deletion ON musteriler;
CREATE TRIGGER trigger_customer_deletion
    BEFORE DELETE ON musteriler
    FOR EACH ROW
    EXECUTE FUNCTION handle_customer_deletion();

-- 8. İstatistik fonksiyonları
CREATE OR REPLACE FUNCTION get_customer_statistics(customer_id INTEGER)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'toplam_siparis', COUNT(*),
        'aktif_siparis', COUNT(CASE WHEN tamamlandi = false OR tamamlandi IS NULL THEN 1 END),
        'tamamlanan_siparis', COUNT(CASE WHEN tamamlandi = true THEN 1 END),
        'toplam_ciro', COALESCE(SUM(toplam_maliyet), 0),
        'ortalama_siparis_degeri', COALESCE(AVG(toplam_maliyet), 0),
        'ilk_siparis', MIN(siparis_tarihi),
        'son_siparis', MAX(siparis_tarihi),
        'en_cok_siparis_verilen_marka', (
            SELECT marka 
            FROM triko_takip 
            WHERE musteri_id = customer_id 
            GROUP BY marka 
            ORDER BY COUNT(*) DESC 
            LIMIT 1
        )
    ) INTO result
    FROM triko_takip
    WHERE musteri_id = customer_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 9. Örnek veri güncelleme (test için)
-- Varsayılan olarak ilk 5 siparişi ilk müşteriye ata
UPDATE triko_takip 
SET musteri_id = (SELECT id FROM musteriler ORDER BY id LIMIT 1)
WHERE id IN (SELECT id FROM triko_takip ORDER BY id LIMIT 5);

-- 10. Başarı mesajı
DO $$ 
BEGIN 
    RAISE NOTICE 'Müşteri-Sipariş entegrasyonu başarıyla tamamlandı!';
    RAISE NOTICE 'Yeni kolonlar eklendi: musteri_id, siparis_tarihi, siparis_notu, toplam_maliyet, kur';
    RAISE NOTICE 'View oluşturuldu: musteri_siparis_ozet';
    RAISE NOTICE 'Fonksiyon eklendi: get_customer_statistics(customer_id)';
END $$;
