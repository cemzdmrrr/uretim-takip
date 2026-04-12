-- Atama tabloları için eksik sütunları ekle
-- Bu SQL dosyasını Supabase SQL Editor'da çalıştırın

-- ===== YIKAMA_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'yikama_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- ===== DOKUMA_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dokuma_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- ===== KONFEKSIYON_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- ===== NAKIS_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'nakis_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- ===== ILIK_DUGME_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- ===== UTU_ATAMALARI =====
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE utu_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE utu_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'utu_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE utu_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- Mevcut kayıtlarda adet bilgisi yoksa triko_takip'ten al ve güncelle
UPDATE yikama_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = yikama_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = yikama_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = yikama_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

UPDATE dokuma_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = dokuma_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = dokuma_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = dokuma_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

UPDATE konfeksiyon_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = konfeksiyon_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = konfeksiyon_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = konfeksiyon_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

UPDATE nakis_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = nakis_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = nakis_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = nakis_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

UPDATE ilik_dugme_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = ilik_dugme_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = ilik_dugme_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = ilik_dugme_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

UPDATE utu_atamalari SET 
    adet = COALESCE(adet, (SELECT adet FROM triko_takip WHERE id = utu_atamalari.model_id)),
    talep_edilen_adet = COALESCE(talep_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = utu_atamalari.model_id)),
    kabul_edilen_adet = COALESCE(kabul_edilen_adet, adet, (SELECT adet FROM triko_takip WHERE id = utu_atamalari.model_id))
WHERE adet IS NULL OR adet = 0;

-- Başarı mesajı
SELECT 'Tüm atama tabloları güncellendi!' as sonuc;
