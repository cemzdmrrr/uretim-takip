-- ÜRETIM WORKFLOW MİGRATION - HATA GİDERİLMİŞ VERSİYON
-- Bu dosya gelişmiş üretim workflow'u için tüm veritabanı değişikliklerini yapar

-- Önce mevcut tabloyu kontrol et
SELECT 'Başlıyor: Üretim kayıtları tablosu mevcut mu kontrol ediliyor...' as durum;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'uretim_kayitlari') THEN
        RAISE EXCEPTION 'uretim_kayitlari tablosu bulunamadı! Önce tabloyu oluşturun.';
    END IF;
    RAISE NOTICE 'uretim_kayitlari tablosu mevcut, devam ediliyor...';
END $$;

-- 1. YENİ SÜTUNLARI EKLE
DO $$
BEGIN
    RAISE NOTICE 'Yeni sütunlar ekleniyor...';
    
    -- baslama_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'baslama_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN baslama_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✓ baslama_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE '- baslama_tarihi sütunu zaten mevcut';
    END IF;

    -- bitis_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'bitis_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN bitis_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✓ bitis_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE '- bitis_tarihi sütunu zaten mevcut';
    END IF;

    -- firma_onay_durumu sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_durumu'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_durumu BOOLEAN;
        RAISE NOTICE '✓ firma_onay_durumu sütunu eklendi';
    ELSE
        RAISE NOTICE '- firma_onay_durumu sütunu zaten mevcut';
    END IF;

    -- firma_onay_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✓ firma_onay_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE '- firma_onay_tarihi sütunu zaten mevcut';
    END IF;

    -- firma_onay_user_id sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_user_id'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_user_id UUID;
        RAISE NOTICE '✓ firma_onay_user_id sütunu eklendi';
    ELSE
        RAISE NOTICE '- firma_onay_user_id sütunu zaten mevcut';
    END IF;

    -- notlar sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'notlar'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN notlar TEXT;
        RAISE NOTICE '✓ notlar sütunu eklendi';
    ELSE
        RAISE NOTICE '- notlar sütunu zaten mevcut';
    END IF;

    -- kalite_onay_durumu sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'kalite_onay_durumu'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN kalite_onay_durumu BOOLEAN;
        RAISE NOTICE '✓ kalite_onay_durumu sütunu eklendi';
    ELSE
        RAISE NOTICE '- kalite_onay_durumu sütunu zaten mevcut';
    END IF;

    -- kalite_kontrol_user_id sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'kalite_kontrol_user_id'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN kalite_kontrol_user_id UUID;
        RAISE NOTICE '✓ kalite_kontrol_user_id sütunu eklendi';
    ELSE
        RAISE NOTICE '- kalite_kontrol_user_id sütunu zaten mevcut';
    END IF;

    -- kalite_kontrol_tarihi sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'kalite_kontrol_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN kalite_kontrol_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✓ kalite_kontrol_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE '- kalite_kontrol_tarihi sütunu zaten mevcut';
    END IF;

    -- kalite_notlari sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'kalite_notlari'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN kalite_notlari TEXT;
        RAISE NOTICE '✓ kalite_notlari sütunu eklendi';
    ELSE
        RAISE NOTICE '- kalite_notlari sütunu zaten mevcut';
    END IF;

    RAISE NOTICE 'Sütun ekleme işlemi tamamlandı.';
END $$;

-- 2. ESKİ CHECK CONSTRAINT'İ KALDIR
DO $$
BEGIN
    RAISE NOTICE 'Eski constraint kontrol ediliyor...';
    
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'uretim_kayitlari'
        AND constraint_name = 'uretim_kayitlari_durum_check'
        AND constraint_type = 'CHECK'
    ) THEN
        ALTER TABLE uretim_kayitlari DROP CONSTRAINT uretim_kayitlari_durum_check;        
        RAISE NOTICE '✓ Eski durum check constraint kaldırıldı';
    ELSE
        RAISE NOTICE '- Eski durum check constraint bulunamadı (normal)';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Check constraint kaldırma hatası: %', SQLERRM;
END $$;

-- 3. YENİ CHECK CONSTRAINT EKLE
DO $$
BEGIN
    RAISE NOTICE 'Yeni constraint ekleniyor...';
    
    ALTER TABLE uretim_kayitlari
    ADD CONSTRAINT uretim_kayitlari_durum_check
    CHECK (durum IN (
        'firma_onay_bekliyor',
        'uretim_baslamadi',
        'uretimde',
        'uretim_tamamlandi',
        'kalite_bekliyor',
        'kalite_onaylandi',
        'kalite_reddedildi',
        'sevkiyat_bekliyor',
        'sevk_edildi',
        'tamamlandi',
        -- Eski durumlar (geriye uyumluluk için)
        'beklemede',
        'devam_ediyor',
        'tamamlandi_old'
    ));
    
    RAISE NOTICE '✓ Yeni durum check constraint eklendi';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Check constraint ekleme hatası: %', SQLERRM;
        RAISE;
END $$;

-- 4. MEVCUT KAYITLARI GÜNCELLENEBİLİR DURUMA GETİR
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE 'Mevcut kayıtlar güncelleniyor...';
    
    UPDATE uretim_kayitlari
    SET durum = 'kalite_bekliyor'
    WHERE durum NOT IN (
        'firma_onay_bekliyor',
        'uretim_baslamadi',
        'uretimde',
        'uretim_tamamlandi',
        'kalite_bekliyor',
        'kalite_onaylandi',
        'kalite_reddedildi',
        'sevkiyat_bekliyor',
        'sevk_edildi',
        'tamamlandi'
    );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✓ % kayıt güncellendi', updated_count;
END $$;

-- 5. RLS POLİCY GÜNCELLEMELERİ
DO $$
BEGIN
    RAISE NOTICE 'RLS policy''ler güncelleniyor...';
    
    -- Önce mevcut policy'leri kaldır
    DROP POLICY IF EXISTS "uretim_kayitlari_select_policy" ON uretim_kayitlari;
    DROP POLICY IF EXISTS "uretim_kayitlari_insert_policy" ON uretim_kayitlari;
    DROP POLICY IF EXISTS "uretim_kayitlari_update_policy" ON uretim_kayitlari;
    DROP POLICY IF EXISTS "uretim_kayitlari_delete_policy" ON uretim_kayitlari;
    
    -- Yeni policy'leri oluştur
    CREATE POLICY "uretim_kayitlari_select_policy" 
    ON uretim_kayitlari FOR SELECT 
    USING (true);

    CREATE POLICY "uretim_kayitlari_insert_policy" 
    ON uretim_kayitlari FOR INSERT 
    WITH CHECK (true);

    CREATE POLICY "uretim_kayitlari_update_policy" 
    ON uretim_kayitlari FOR UPDATE 
    USING (true) 
    WITH CHECK (true);

    CREATE POLICY "uretim_kayitlari_delete_policy" 
    ON uretim_kayitlari FOR DELETE 
    USING (true);
    
    RAISE NOTICE '✓ RLS policy''ler güncellendi';
END $$;

-- 6. SEQUENCE İZİNLERİ (varsa)
DO $$
DECLARE
    seq_name TEXT;
BEGIN
    RAISE NOTICE 'Sequence izinleri kontrol ediliyor...';
    
    -- Tabloyla ilişkili sequence'i bul
    SELECT pg_get_serial_sequence('uretim_kayitlari', 'id') INTO seq_name;
    
    IF seq_name IS NOT NULL THEN
        EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %I TO authenticated', seq_name);
        EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE %I TO anon', seq_name);
        RAISE NOTICE '✓ Sequence izinleri güncellendi: %', seq_name;
    ELSE
        RAISE NOTICE '- Sequence bulunamadı veya tablo serial değil';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sequence izin hatası: %', SQLERRM;
END $$;

-- 7. TABLO İZİNLERİ
DO $$
BEGIN
    RAISE NOTICE 'Tablo izinleri güncelleniyor...';
    
    GRANT ALL ON uretim_kayitlari TO authenticated;
    GRANT SELECT ON uretim_kayitlari TO anon;
    
    RAISE NOTICE '✓ Tablo izinleri güncellendi';
END $$;

-- 8. SONUÇ KONTROLÜ
SELECT 'DURUM DAĞILIMI:' as baslik;

SELECT
    COALESCE(durum, 'NULL') as durum,
    COUNT(*) as kayit_sayisi
FROM uretim_kayitlari
GROUP BY durum
ORDER BY durum;

-- Başarılı tamamlama mesajı
SELECT '🎉 Üretim workflow migration başarıyla tamamlandı!' as sonuc;

-- Son kontrol
SELECT 
    'Migration tamamlandı. Toplam ' || COUNT(*) || ' kayıt bulunuyor.' as ozet
FROM uretim_kayitlari;
