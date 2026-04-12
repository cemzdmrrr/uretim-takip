-- Paketleme/Sevkiyat tablosu constraint düzeltmeleri
-- Sevkiyat durumları ve hedef aşama değerlerini ekliyoruz

-- 1. paketleme_atamalari tablosunda durum constraint'ini güncelle
ALTER TABLE paketleme_atamalari DROP CONSTRAINT IF EXISTS paketleme_atamalari_durum_check;
ALTER TABLE paketleme_atamalari ADD CONSTRAINT paketleme_atamalari_durum_check 
  CHECK (durum IN (
    'atandi', 
    'onaylandi', 
    'baslandi', 
    'uretimde', 
    'baslatildi', 
    'kismi_tamamlandi', 
    'tamamlandi', 
    'reddedildi', 
    'iptal',
    'beklemede',
    'kontrol_bekliyor',
    'kontrolde',
    -- Sevkiyat durumları
    'sevk_bekliyor',
    'sevk_ediliyor', 
    'sevk_edildi',
    'kismen_sevk',
    'hazirlaniyor'
  ));

-- 2. hedef_asama constraint'ini güncelle (varsa)
DO $$
BEGIN
    -- Önce mevcut constraint'i kaldır
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'paketleme_atamalari_hedef_asama_check' 
        AND table_name = 'paketleme_atamalari'
    ) THEN
        ALTER TABLE paketleme_atamalari DROP CONSTRAINT paketleme_atamalari_hedef_asama_check;
    END IF;
END $$;

-- hedef_asama sütunu yoksa ekle
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'hedef_asama'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN hedef_asama VARCHAR(50);
        RAISE NOTICE 'hedef_asama sütunu eklendi';
    END IF;
END $$;

-- hedef_asama için constraint ekle (isteğe bağlı, tüm aşamalara izin ver)
-- Bu constraint eklenmez çünkü herhangi bir aşamaya sevk yapılabilir

-- 3. Mevcut hatalı kayıtları düzelt (varsa)
UPDATE paketleme_atamalari 
SET durum = 'sevk_bekliyor' 
WHERE durum IS NULL OR durum = '';

-- 4. Sevkiyat için gerekli ek sütunlar
DO $$
BEGIN
    -- sevk_tarihi
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'sevk_tarihi'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN sevk_tarihi TIMESTAMPTZ;
    END IF;
    
    -- sevk_adresi
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'sevk_adresi'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN sevk_adresi TEXT;
    END IF;
    
    -- kargo_firmasi
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'kargo_firmasi'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN kargo_firmasi VARCHAR(100);
    END IF;
    
    -- takip_no
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'takip_no'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN takip_no VARCHAR(100);
    END IF;
    
    -- fire_adet
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'paketleme_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- Başarı mesajı
SELECT 'paketleme_atamalari tablosu sevkiyat için güncellendi!' as sonuc;
