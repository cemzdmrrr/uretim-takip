-- Üretim kayıtları durum enum güncelleme
-- Bu dosya yeni workflow durumlarını ekler

-- Önce mevcut check constraint'i kaldır
DO $$
BEGIN
    -- Check constraint varsa kaldır
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

-- Yeni check constraint ekle (tüm durumları içeren)
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

-- Mevcut kayıtlardaki eski durumları güncelle
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

-- Güncellenen kayıt sayısını göster
SELECT
    durum,
    COUNT(*) as kayit_sayisi
FROM uretim_kayitlari
GROUP BY durum
ORDER BY durum;
