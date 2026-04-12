-- Atama tabloları için eksik sütunları ekle
-- Bu SQL dosyasını Supabase SQL Editor'da çalıştırın

-- yikama_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    -- updated_at sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    -- onay_tarihi sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    -- tamamlanan_adet sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    
    -- adet sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    
    -- talep_edilen_adet sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    
    -- kabul_edilen_adet sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    
    -- uretim_baslangic_tarihi sütunu
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'yikama_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- dokuma_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN adet INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'talep_edilen_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN talep_edilen_adet INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'kabul_edilen_adet') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN kabul_edilen_adet INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'dokuma_atamalari' AND column_name = 'uretim_baslangic_tarihi') THEN
        ALTER TABLE dokuma_atamalari ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
    END IF;
END $$;

-- konfeksiyon_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'konfeksiyon_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- nakis_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'nakis_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'nakis_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'nakis_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- ilik_dugme_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'ilik_dugme_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- utu_atamalari tablosuna eksik sütunları ekle
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'utu_atamalari' AND column_name = 'updated_at') THEN
        ALTER TABLE utu_atamalari ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'utu_atamalari' AND column_name = 'onay_tarihi') THEN
        ALTER TABLE utu_atamalari ADD COLUMN onay_tarihi TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'utu_atamalari' AND column_name = 'tamamlanan_adet') THEN
        ALTER TABLE utu_atamalari ADD COLUMN tamamlanan_adet INTEGER DEFAULT 0;
    END IF;
END $$;

-- Başarı mesajı
SELECT 'Tüm atama tabloları güncellendi - updated_at, onay_tarihi, tamamlanan_adet sütunları eklendi.' as sonuc;
