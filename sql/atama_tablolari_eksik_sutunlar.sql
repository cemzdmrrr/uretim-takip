-- Tüm atama tablolarına eksik sütunları ekle
-- baslama_tarihi, planlanan_bitis_tarihi, fire_adet

-- ==========================================
-- KONFEKSİYON ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ==========================================
-- YIKAMA ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ==========================================
-- ÜTÜ ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE utu_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE utu_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ==========================================
-- İLİK DÜĞME ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ==========================================
-- DOKUMA ATAMALARI (varsa kontrol et)
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ==========================================
-- KALİTE KONTROL ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'red_sebebi') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN red_sebebi TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kalite_kontrol_atamalari' AND column_name = 'atanan_kullanici_id') THEN
        ALTER TABLE kalite_kontrol_atamalari ADD COLUMN atanan_kullanici_id UUID;
    END IF;
END $$;

-- ==========================================
-- PAKETLEME ATAMALARI
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'paketleme_atamalari' AND column_name = 'baslama_tarihi') THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN baslama_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'paketleme_atamalari' AND column_name = 'planlanan_bitis_tarihi') THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN planlanan_bitis_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'paketleme_atamalari' AND column_name = 'fire_adet') THEN
        ALTER TABLE paketleme_atamalari ADD COLUMN fire_adet INTEGER DEFAULT 0;
    END IF;
END $$;

SELECT 'Tüm atama tablolarına eksik sütunlar eklendi!' as sonuc;
