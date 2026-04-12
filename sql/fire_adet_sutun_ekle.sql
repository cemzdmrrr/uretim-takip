-- Fire adet sütunlarını atama tablolarına ekle
-- Bu sütunlar fire (defolu/kusurlu) üretim adetlerini takip etmek için kullanılır

-- Dokuma atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'dokuma_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'dokuma_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'dokuma_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- Konfeksiyon atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'konfeksiyon_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'konfeksiyon_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- Yıkama atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'yikama_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE yikama_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'yikama_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'yikama_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- Ütü atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'utu_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE utu_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'utu_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'utu_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- İlik Düğme atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'ilik_dugme_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'ilik_dugme_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- Kalite Kontrol atamaları için fire_adet sütunu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'fire_adet'
    ) THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
        RAISE NOTICE 'kalite_kontrol_atamalari.fire_adet sütunu eklendi';
    ELSE
        RAISE NOTICE 'kalite_kontrol_atamalari.fire_adet sütunu zaten mevcut';
    END IF;
END $$;

-- Beden bazlı fire takibi için view oluştur (raporlama için)
CREATE OR REPLACE VIEW fire_rapor_view AS
SELECT 
    'dokuma' as asama,
    da.id as atama_id,
    da.model_id,
    tt.marka,
    tt.item_no,
    tt.renk,
    da.tamamlanan_adet,
    da.fire_adet,
    da.kabul_edilen_adet,
    da.tamamlama_tarihi,
    CASE 
        WHEN da.tamamlanan_adet > 0 THEN 
            ROUND((da.fire_adet::NUMERIC / (da.tamamlanan_adet + da.fire_adet)::NUMERIC) * 100, 2)
        ELSE 0 
    END as fire_orani
FROM dokuma_atamalari da
JOIN triko_takip tt ON tt.id = da.model_id::uuid
WHERE da.fire_adet > 0

UNION ALL

SELECT 
    'konfeksiyon' as asama,
    ka.id as atama_id,
    ka.model_id,
    tt.marka,
    tt.item_no,
    tt.renk,
    ka.tamamlanan_adet,
    ka.fire_adet,
    ka.kabul_edilen_adet,
    ka.tamamlama_tarihi,
    CASE 
        WHEN ka.tamamlanan_adet > 0 THEN 
            ROUND((ka.fire_adet::NUMERIC / (ka.tamamlanan_adet + ka.fire_adet)::NUMERIC) * 100, 2)
        ELSE 0 
    END as fire_orani
FROM konfeksiyon_atamalari ka
JOIN triko_takip tt ON tt.id = ka.model_id::uuid
WHERE ka.fire_adet > 0

UNION ALL

SELECT 
    'yikama' as asama,
    ya.id as atama_id,
    ya.model_id,
    tt.marka,
    tt.item_no,
    tt.renk,
    ya.tamamlanan_adet,
    ya.fire_adet,
    ya.kabul_edilen_adet,
    ya.tamamlama_tarihi,
    CASE 
        WHEN ya.tamamlanan_adet > 0 THEN 
            ROUND((ya.fire_adet::NUMERIC / (ya.tamamlanan_adet + ya.fire_adet)::NUMERIC) * 100, 2)
        ELSE 0 
    END as fire_orani
FROM yikama_atamalari ya
JOIN triko_takip tt ON tt.id = ya.model_id::uuid
WHERE ya.fire_adet > 0;

-- Genel fire özet view'ı
CREATE OR REPLACE VIEW fire_ozet_view AS
SELECT 
    asama,
    COUNT(*) as toplam_is,
    SUM(tamamlanan_adet) as toplam_uretim,
    SUM(fire_adet) as toplam_fire,
    ROUND(AVG(fire_orani), 2) as ortalama_fire_orani
FROM fire_rapor_view
GROUP BY asama
ORDER BY asama;

-- Başarı mesajı
SELECT 'Fire raporlama view''ları oluşturuldu!' as sonuc;
