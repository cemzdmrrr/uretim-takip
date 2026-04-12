-- ÜRETIM WORKFLOW KOMPLE MİGRATION
-- Bu dosya gelişmiş üretim workflow'u için tüm veritabanı değişikliklerini yapar

-- 1. ÖNCE YENİ SÜTUNLARI EKLE
DO $$
BEGIN
    -- baslama_tarihi sütunu ekle
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

    -- notlar sütunu ekle
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'notlar'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN notlar TEXT;
        RAISE NOTICE 'notlar sütunu eklendi';
    END IF;

END $$;

-- 2. ESKİ CHECK CONSTRAINT'İ KALDIR
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'uretim_kayitlari'
        AND constraint_name = 'uretim_kayitlari_durum_check'
    ) THEN
        ALTER TABLE uretim_kayitlari DROP CONSTRAINT uretim_kayitlari_durum_check;        
        RAISE NOTICE 'Eski durum check constraint kaldırıldı';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Check constraint kaldırma hatası: %', SQLERRM;
END $$;

-- 3. YENİ CHECK CONSTRAINT EKLE
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

-- 4. MEVCUT KAYITLARI GÜNCELLENEBİLİR DURUMA GETİR
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

-- 5. RLS POLİCY GÜNCELLEMELERİ
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

-- 6. SEQUENCE İZİNLERİ (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'uretim_kayitlari_id_seq') THEN
        GRANT USAGE, SELECT ON SEQUENCE uretim_kayitlari_id_seq TO authenticated;
        GRANT USAGE, SELECT ON SEQUENCE uretim_kayitlari_id_seq TO anon;
        RAISE NOTICE 'Sequence izinleri güncellendi';
    ELSE
        RAISE NOTICE 'uretim_kayitlari_id_seq sequence bulunamadı, izin güncellemesi atlandı';
    END IF;
END $$;

-- 7. TABLO İZİNLERİ
GRANT ALL ON uretim_kayitlari TO authenticated;
GRANT SELECT ON uretim_kayitlari TO anon;

-- 8. SONUÇ KONTROLÜ
SELECT
    durum,
    COUNT(*) as kayit_sayisi
FROM uretim_kayitlari
GROUP BY durum
ORDER BY durum;

-- Başarılı tamamlama mesajı
SELECT 'Üretim workflow migration başarıyla tamamlandı!' as sonuc;
