-- Üretim kayıtları tablosuna yeni sütunlar ekleme
-- Bu dosya gelişmiş workflow için gerekli sütunları ekler

DO $$
BEGIN
    -- baslangic_tarihi sütunu ekle (baslama_tarihi olarak güncelle)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'baslama_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN baslama_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'baslama_tarihi sütunu eklendi';
    END IF;

    -- bitis_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'bitis_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN bitis_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'bitis_tarihi sütunu eklendi';
    END IF;

    -- firma_onay_durumu sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_durumu'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_durumu BOOLEAN;
        RAISE NOTICE 'firma_onay_durumu sütunu eklendi';
    END IF;

    -- firma_onay_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'firma_onay_tarihi sütunu eklendi';
    END IF;

    -- firma_onay_user_id sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_user_id'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE 'firma_onay_user_id sütunu eklendi';
    END IF;

    -- notlar sütunu ekle (eğer yoksa)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'notlar'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN notlar TEXT;
        RAISE NOTICE 'notlar sütunu eklendi';
    END IF;

    RAISE NOTICE 'Tüm yeni sütunlar kontrol edildi ve eklendi';
END $$;

-- Mevcut durum değerlerini güncelle
-- Yeni workflow durumları:
-- 'firma_onay_bekliyor' - Firma onayı bekliyor (sevkiyat sonrası)
-- 'uretimde' - Üretim devam ediyor (firma onayından sonra)
-- 'uretim_tamamlandi' - Firma üretimi tamamladı
-- 'kalite_bekliyor' - Kalite kontrolü bekliyor
-- 'kalite_onaylandi' - Kalite onaylandı
-- 'sevkiyat_bekliyor' - Sevkiyat bekliyor
-- 'sevk_edildi' - Sevk edildi
-- 'tamamlandi' - Ütü aşaması tamamlandı (son durum)

-- Tablodaki sütunları kontrol et
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'uretim_kayitlari' 
ORDER BY ordinal_position;
