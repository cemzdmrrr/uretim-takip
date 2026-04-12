-- PERSONEL YÖNETİMİ TUTARSIZLIK DÜZELTMELERİ
-- Bu script veritabanındaki personel ile ilgili tutarsızlıkları düzeltir
-- Tarih: 2026-01-04

-- =====================================================
-- 1. PERSONEL TABLOSU - ad ve soyad KOLON EKLEMELERİ
-- =====================================================

-- Eğer ad_soyad varsa ve ad/soyad yoksa, ayrı kolonlara böl
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS ad VARCHAR(100);
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS soyad VARCHAR(100);

-- Mevcut ad_soyad verilerini ad ve soyad'a böl (eğer ad_soyad kolonu varsa)
DO $$
BEGIN
    -- Sadece ad_soyad kolonu varsa çalıştır
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'personel' AND column_name = 'ad_soyad'
    ) THEN
        UPDATE public.personel
        SET 
            ad = CASE
                WHEN ad_soyad IS NOT NULL AND position(' ' in ad_soyad) > 0 
                THEN split_part(ad_soyad, ' ', 1)
                ELSE ad_soyad
            END,
            soyad = CASE
                WHEN ad_soyad IS NOT NULL AND position(' ' in ad_soyad) > 0 
                THEN trim(substring(ad_soyad from position(' ' in ad_soyad) + 1))
                ELSE ''
            END
        WHERE (ad IS NULL OR ad = '') AND ad_soyad IS NOT NULL;
        
        RAISE NOTICE 'ad_soyad kolonu ad ve soyad olarak bölündü';
    END IF;
END $$;

-- =====================================================
-- 2. PERSONEL VIEW - ad_soyad için backward compatibility
-- =====================================================

-- Eski kod için ad_soyad döndüren view oluştur
CREATE OR REPLACE VIEW personel_view AS
SELECT 
    *,
    COALESCE(ad, '') || ' ' || COALESCE(soyad, '') AS ad_soyad
FROM personel;

-- =====================================================
-- 3. İZİNLER TABLOSU - KOLON İSİM DÜZELTMELERİ
-- =====================================================

-- İzinler tablosunda baslama_tarihi ve bitis_tarihi kolonlarını ekle
ALTER TABLE public.izinler ADD COLUMN IF NOT EXISTS baslama_tarihi DATE;
ALTER TABLE public.izinler ADD COLUMN IF NOT EXISTS bitis_tarihi DATE;

-- Eğer baslangic/bitis varsa verileri kopyala
DO $$
BEGIN
    -- baslangic -> baslama_tarihi
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'izinler' AND column_name = 'baslangic'
    ) THEN
        UPDATE public.izinler
        SET baslama_tarihi = baslangic::DATE
        WHERE baslama_tarihi IS NULL AND baslangic IS NOT NULL;
        
        RAISE NOTICE 'baslangic verileri baslama_tarihi kolonuna kopyalandı';
    END IF;
    
    -- bitis -> bitis_tarihi
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'izinler' AND column_name = 'bitis'
    ) THEN
        UPDATE public.izinler
        SET bitis_tarihi = bitis::DATE
        WHERE bitis_tarihi IS NULL AND bitis IS NOT NULL;
        
        RAISE NOTICE 'bitis verileri bitis_tarihi kolonuna kopyalandı';
    END IF;
END $$;

-- =====================================================
-- 4. MESAI TABLOSU - onay_durumu CHECK CONSTRAINT DÜZELTMESİ
-- =====================================================

-- Eski constraint'i kaldır ve yenisini ekle (eğer varsa)
DO $$
BEGIN
    -- Mesai tablosu için constraint düzeltmesi
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'mesai' AND constraint_type = 'CHECK'
    ) THEN
        -- Mevcut check constraint'leri kaldır
        ALTER TABLE public.mesai DROP CONSTRAINT IF EXISTS mesai_onay_durumu_check;
    END IF;
    
    -- Yeni constraint ekle
    ALTER TABLE public.mesai ADD CONSTRAINT mesai_onay_durumu_check 
        CHECK (onay_durumu IN ('beklemede', 'onaylandi', 'red', 'iptal'));
        
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Mesai constraint güncellemesi atlandı: %', SQLERRM;
END $$;

-- =====================================================
-- 5. ODEME KAYITLARI - Tek tablo standardizasyonu
-- =====================================================

-- odeme_kayitlari tablosunda eksik kolonları ekle
ALTER TABLE public.odeme_kayitlari ADD COLUMN IF NOT EXISTS personel_id UUID;
ALTER TABLE public.odeme_kayitlari ADD COLUMN IF NOT EXISTS tur VARCHAR(50);
ALTER TABLE public.odeme_kayitlari ADD COLUMN IF NOT EXISTS tutar DECIMAL(10,2);
ALTER TABLE public.odeme_kayitlari ADD COLUMN IF NOT EXISTS tarih DATE;
ALTER TABLE public.odeme_kayitlari ADD COLUMN IF NOT EXISTS durum VARCHAR(20) DEFAULT 'beklemede';

-- =====================================================
-- 6. INDEX'LER - Performans iyileştirmesi
-- =====================================================

-- Personel tablosu için index'ler
CREATE INDEX IF NOT EXISTS idx_personel_ad ON personel(ad);
CREATE INDEX IF NOT EXISTS idx_personel_soyad ON personel(soyad);
CREATE INDEX IF NOT EXISTS idx_personel_departman ON personel(departman);
CREATE INDEX IF NOT EXISTS idx_personel_pozisyon ON personel(pozisyon);

-- İzinler tablosu için index'ler
CREATE INDEX IF NOT EXISTS idx_izinler_baslama_tarihi ON izinler(baslama_tarihi);
CREATE INDEX IF NOT EXISTS idx_izinler_personel_id ON izinler(personel_id);
CREATE INDEX IF NOT EXISTS idx_izinler_onay_durumu ON izinler(onay_durumu);

-- Mesai tablosu için index'ler  
CREATE INDEX IF NOT EXISTS idx_mesai_personel_id ON mesai(personel_id);
CREATE INDEX IF NOT EXISTS idx_mesai_tarih ON mesai(tarih);
CREATE INDEX IF NOT EXISTS idx_mesai_onay_durumu ON mesai(onay_durumu);

-- =====================================================
-- 7. KONTROL SORGUSU
-- =====================================================

SELECT 
    'Personel' as tablo,
    COUNT(*) as kayit_sayisi,
    COUNT(*) FILTER (WHERE ad IS NOT NULL AND ad != '') as ad_dolu,
    COUNT(*) FILTER (WHERE soyad IS NOT NULL AND soyad != '') as soyad_dolu
FROM personel
UNION ALL
SELECT 
    'İzinler' as tablo,
    COUNT(*) as kayit_sayisi,
    COUNT(*) FILTER (WHERE baslama_tarihi IS NOT NULL) as baslama_tarihi_dolu,
    COUNT(*) FILTER (WHERE bitis_tarihi IS NOT NULL) as bitis_tarihi_dolu
FROM izinler
UNION ALL
SELECT 
    'Mesai' as tablo,
    COUNT(*) as kayit_sayisi,
    COUNT(*) FILTER (WHERE personel_id IS NOT NULL) as personel_id_dolu,
    COUNT(*) FILTER (WHERE onay_durumu IS NOT NULL) as onay_durumu_dolu
FROM mesai;

-- Tamamlandı mesajı
SELECT 'Personel yönetimi tutarsızlık düzeltmeleri tamamlandı!' as durum;
