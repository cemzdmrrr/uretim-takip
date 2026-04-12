-- =============================================
-- RAPORLAR SİSTEMİ İÇİN EKSİK SÜTUNLARI EKLEME
-- =============================================

-- Bu script'i Supabase SQL Editor'da çalıştırın

DO $$
BEGIN
    RAISE NOTICE 'Raporlar sistemi için eksik sütunları kontrol ediyor ve ekliyor...';

    -- 1. KAŞE ONAY SÜTUNLARI
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'kase_onay_durumu'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN kase_onay_durumu BOOLEAN;
        RAISE NOTICE 'kase_onay_durumu sütunu eklendi';
    ELSE
        RAISE NOTICE 'kase_onay_durumu sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'kase_onay_tarihi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN kase_onay_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'kase_onay_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE 'kase_onay_tarihi sütunu zaten mevcut';
    END IF;

    -- 2. NUMUNE SÜTUNLARI (Bazıları zaten eklenmiş olabilir)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'first_fit_gonderildi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN first_fit_gonderildi TEXT CHECK (first_fit_gonderildi IN ('evet', 'hayir'));
        RAISE NOTICE 'first_fit_gonderildi sütunu eklendi';
    ELSE
        RAISE NOTICE 'first_fit_gonderildi sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'first_fit_aciklama'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN first_fit_aciklama TEXT;
        RAISE NOTICE 'first_fit_aciklama sütunu eklendi';
    ELSE
        RAISE NOTICE 'first_fit_aciklama sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'size_set_gonderildi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN size_set_gonderildi TEXT CHECK (size_set_gonderildi IN ('evet', 'hayir'));
        RAISE NOTICE 'size_set_gonderildi sütunu eklendi';
    ELSE
        RAISE NOTICE 'size_set_gonderildi sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'size_set_aciklama'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN size_set_aciklama TEXT;
        RAISE NOTICE 'size_set_aciklama sütunu eklendi';
    ELSE
        RAISE NOTICE 'size_set_aciklama sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'pps_numunesi_gonderildi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN pps_numunesi_gonderildi TEXT CHECK (pps_numunesi_gonderildi IN ('evet', 'hayir'));
        RAISE NOTICE 'pps_numunesi_gonderildi sütunu eklendi';
    ELSE
        RAISE NOTICE 'pps_numunesi_gonderildi sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'pps_numunesi_aciklama'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN pps_numunesi_aciklama TEXT;
        RAISE NOTICE 'pps_numunesi_aciklama sütunu eklendi';
    ELSE
        RAISE NOTICE 'pps_numunesi_aciklama sütunu zaten mevcut';
    END IF;

    -- 3. ÜRETİM SÜRECİ SÜTUNLARI
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'iplik_geldi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN iplik_geldi BOOLEAN DEFAULT false;
        RAISE NOTICE 'iplik_geldi sütunu eklendi';
    ELSE
        RAISE NOTICE 'iplik_geldi sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'iplik_gelis_tarihi'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN iplik_gelis_tarihi TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'iplik_gelis_tarihi sütunu eklendi';
    ELSE
        RAISE NOTICE 'iplik_gelis_tarihi sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'orguye_baslayabilir'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN orguye_baslayabilir BOOLEAN DEFAULT false;
        RAISE NOTICE 'orguye_baslayabilir sütunu eklendi';
    ELSE
        RAISE NOTICE 'orguye_baslayabilir sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'orgu_firma'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN orgu_firma TEXT;
        RAISE NOTICE 'orgu_firma sütunu eklendi';
    ELSE
        RAISE NOTICE 'orgu_firma sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'konfeksiyon_firma'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN konfeksiyon_firma TEXT;
        RAISE NOTICE 'konfeksiyon_firma sütunu eklendi';
    ELSE
        RAISE NOTICE 'konfeksiyon_firma sütunu zaten mevcut';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'triko_takip' AND column_name = 'utu_firma'
    ) THEN
        ALTER TABLE triko_takip ADD COLUMN utu_firma TEXT;
        RAISE NOTICE 'utu_firma sütunu eklendi';
    ELSE
        RAISE NOTICE 'utu_firma sütunu zaten mevcut';
    END IF;

    -- 4. PERFORMANS İNDEKSLERİ OLUŞTUR
    CREATE INDEX IF NOT EXISTS idx_triko_takip_kase_onay ON triko_takip(kase_onay_durumu);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_first_fit ON triko_takip(first_fit_gonderildi);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_size_set ON triko_takip(size_set_gonderildi);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_pps_numunesi ON triko_takip(pps_numunesi_gonderildi);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_iplik_durumu ON triko_takip(iplik_geldi);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_orgu_hazirlik ON triko_takip(orguye_baslayabilir);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_tamamlandi ON triko_takip(tamamlandi);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_termin ON triko_takip(termin);
    CREATE INDEX IF NOT EXISTS idx_triko_takip_created_at ON triko_takip(created_at);

    RAISE NOTICE 'Performans indeksleri oluşturuldu';

    -- 5. SÜTUN AÇIKLAMALARI
    COMMENT ON COLUMN triko_takip.kase_onay_durumu IS 'Kaşe onay durumu - true: onaylı, false: onaysız, null: beklemede';
    COMMENT ON COLUMN triko_takip.kase_onay_tarihi IS 'Kaşe onayının verildiği tarih';
    COMMENT ON COLUMN triko_takip.first_fit_gonderildi IS 'First Fit numunesi gönderildi mi? (evet/hayir)';
    COMMENT ON COLUMN triko_takip.first_fit_aciklama IS 'First Fit numunesi ile ilgili açıklama';
    COMMENT ON COLUMN triko_takip.size_set_gonderildi IS 'Size Set gönderildi mi? (evet/hayir)';
    COMMENT ON COLUMN triko_takip.size_set_aciklama IS 'Size Set ile ilgili açıklama';
    COMMENT ON COLUMN triko_takip.pps_numunesi_gonderildi IS 'PPS (Production Pre Sample) numunesi gönderildi mi? (evet/hayir)';
    COMMENT ON COLUMN triko_takip.pps_numunesi_aciklama IS 'PPS numunesi ile ilgili açıklama';
    COMMENT ON COLUMN triko_takip.iplik_geldi IS 'İplik geldi mi?';
    COMMENT ON COLUMN triko_takip.iplik_gelis_tarihi IS 'İplik geliş tarihi';
    COMMENT ON COLUMN triko_takip.orguye_baslayabilir IS 'Örgüye başlanıp başlanamayacağını belirtir';
    COMMENT ON COLUMN triko_takip.orgu_firma IS 'Örgüyü yapacak firma';
    COMMENT ON COLUMN triko_takip.konfeksiyon_firma IS 'Konfeksiyonu yapacak firma';
    COMMENT ON COLUMN triko_takip.utu_firma IS 'Ütüyü yapacak firma';

    RAISE NOTICE 'Sütun açıklamaları eklendi';

    -- 6. ÖRNEK TEST VERİSİ (İSTEĞE BAĞLI)
    -- Mevcut kayıtlara örnek veriler ekleyin (dikkatli kullanın!)
    /*
    UPDATE triko_takip SET 
        kase_onay_durumu = (RANDOM() > 0.3)::boolean,
        kase_onay_tarihi = CASE 
            WHEN (RANDOM() > 0.3)::boolean THEN NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 30)
            ELSE NULL 
        END,
        first_fit_gonderildi = CASE 
            WHEN RANDOM() > 0.5 THEN 'evet'
            WHEN RANDOM() > 0.2 THEN 'hayir'
            ELSE NULL
        END,
        size_set_gonderildi = CASE 
            WHEN RANDOM() > 0.4 THEN 'evet'
            WHEN RANDOM() > 0.2 THEN 'hayir'
            ELSE NULL
        END,
        pps_numunesi_gonderildi = CASE 
            WHEN RANDOM() > 0.6 THEN 'evet'
            WHEN RANDOM() > 0.3 THEN 'hayir'
            ELSE NULL
        END,
        iplik_geldi = (RANDOM() > 0.4)::boolean,
        orguye_baslayabilir = (RANDOM() > 0.6)::boolean
    WHERE kase_onay_durumu IS NULL; -- Sadece henüz güncellenmeyen kayıtları güncelle
    */

    RAISE NOTICE '================================================';
    RAISE NOTICE 'RAPORLAR SİSTEMİ HAZIRLIK TAMAMLANDI!';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Tüm gerekli sütunlar kontrol edildi ve eksikler eklendi.';
    RAISE NOTICE 'Performans indeksleri oluşturuldu.';
    RAISE NOTICE 'Raporlar sayfası artık tam fonksiyonel olarak kullanılabilir.';
    RAISE NOTICE '================================================';

END $$;

-- 7. TABLONUN GÜNCEL DURUMUNU KONTROL ET
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'triko_takip'
    AND column_name IN (
        'kase_onay_durumu', 'kase_onay_tarihi',
        'first_fit_gonderildi', 'first_fit_aciklama',
        'size_set_gonderildi', 'size_set_aciklama',
        'pps_numunesi_gonderildi', 'pps_numunesi_aciklama',
        'iplik_geldi', 'iplik_gelis_tarihi',
        'orguye_baslayabilir', 'orgu_firma', 'konfeksiyon_firma', 'utu_firma'
    )
ORDER BY column_name;

-- Son mesaj
SELECT 'Raporlar Sistemi Migration Tamamlandı! 🎉' as status;
