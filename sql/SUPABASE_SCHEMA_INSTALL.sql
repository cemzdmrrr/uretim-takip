-- ============================================
-- ÖNEMLİ: BU DOSYAYI SUPABASE SQL EDITOR'DA ÇALIŞTIRIN
-- ============================================

-- 1. Mevcut tabloları sil (dikkatli olun!)
DROP TABLE IF EXISTS personel_donem CASCADE;
DROP TABLE IF EXISTS donemler CASCADE;

-- 2. Yeni donemler tablosunu oluştur
CREATE TABLE donemler (
    id SERIAL PRIMARY KEY,
    yil INTEGER NOT NULL,
    ay INTEGER NOT NULL CHECK (ay >= 1 AND ay <= 12),
    donem_adi VARCHAR(20) NOT NULL UNIQUE,
    durum VARCHAR(20) DEFAULT 'aktif' CHECK (durum IN ('aktif', 'tamamlandi', 'arsivlendi')),
    olusturan_kullanici_id UUID REFERENCES auth.users(id),
    olusturulma_tarihi TIMESTAMP DEFAULT NOW(),
    guncellenme_tarihi TIMESTAMP DEFAULT NOW(),
    
    -- Aynı yıl/ay kombinasyonu tekrar etmesin
    UNIQUE(yil, ay)
);

-- 3. Personel dönem ilişki tablosunu oluştur
CREATE TABLE personel_donem (
    id SERIAL PRIMARY KEY,
    donem_id INTEGER REFERENCES donemler(id) ON DELETE CASCADE,
    personel_id UUID NOT NULL,
    toplam_mesai_saati DECIMAL(8,2) DEFAULT 0,
    toplam_izin_gunu INTEGER DEFAULT 0,
    toplam_avans DECIMAL(12,2) DEFAULT 0,
    bordro_durumu VARCHAR(20) DEFAULT 'beklemede' CHECK (bordro_durumu IN ('beklemede', 'hazirlandi', 'odendi')),
    olusturulma_tarihi TIMESTAMP DEFAULT NOW(),
    guncellenme_tarihi TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(donem_id, personel_id)
);

-- 4. İndeksler oluştur
CREATE INDEX idx_donemler_durum ON donemler(durum);
CREATE INDEX idx_donemler_yil_ay ON donemler(yil, ay);
CREATE INDEX idx_personel_donem_donem_id ON personel_donem(donem_id);
CREATE INDEX idx_personel_donem_personel_id ON personel_donem(personel_id);

-- 5. RLS politikalarını etkinleştir
ALTER TABLE donemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel_donem ENABLE ROW LEVEL SECURITY;

-- 6. Okuma politikaları
CREATE POLICY "Herkes donemler tablosunu okuyabilir" ON donemler
    FOR SELECT USING (true);

CREATE POLICY "Herkes personel_donem tablosunu okuyabilir" ON personel_donem
    FOR SELECT USING (true);

-- 7. Yazma politikaları (sadece admin/ik)
-- Not: rol sütunu yerine geçici olarak tüm authenticated kullanıcılara izin veriyoruz
-- Daha sonra uygun rol kontrol mekanizmaSı eklenebilir
CREATE POLICY "Authenticated kullanıcılar donemler tablosunu değiştirebilir" ON donemler
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated kullanıcılar personel_donem tablosunu değiştirebilir" ON personel_donem
    FOR ALL USING (auth.uid() IS NOT NULL);

-- 8. Örnek veri ekle
INSERT INTO donemler (yil, ay, donem_adi, durum, olusturulma_tarihi) VALUES
(2024, 12, '2024-12', 'tamamlandi', '2024-12-01 00:00:00'),
(2025, 1, '2025-01', 'tamamlandi', '2025-01-01 00:00:00'),
(2025, 8, '2025-08', 'aktif', '2025-08-01 00:00:00');

-- 9. Başarı mesajı
SELECT 'Dönem yönetimi tabloları başarıyla oluşturuldu!' as mesaj;
