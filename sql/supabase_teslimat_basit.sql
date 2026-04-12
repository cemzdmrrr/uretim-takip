-- İplik Sipariş Takip Sistemi için gerekli tablolar (Basit Versiyon)
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce problematik view'ları ve kolonları temizle
DROP VIEW IF EXISTS iplik_siparis_kalemleri_detay CASCADE;
DROP VIEW IF EXISTS iplik_hareketleri_detay CASCADE;

-- 2. Mevcut kalan_miktar kolonunu kaldır
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE iplik_hareketleri DROP COLUMN kalan_miktar CASCADE;
    EXCEPTION
        WHEN undefined_column THEN
            NULL;
        WHEN OTHERS THEN
            NULL;
    END;
END $$;

-- 3. İplik Sipariş Kalemleri Tablosu
CREATE TABLE IF NOT EXISTS iplik_siparis_kalemleri (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  siparis_id UUID NOT NULL REFERENCES iplik_siparisleri(id) ON DELETE CASCADE,
  kalem_no INTEGER NOT NULL,
  iplik_adi TEXT NOT NULL,
  renk TEXT,
  siparis_miktari NUMERIC(10,2) NOT NULL DEFAULT 0,
  birim TEXT DEFAULT 'kg',
  birim_fiyat NUMERIC(10,2),
  para_birimi TEXT DEFAULT 'TL',
  durum TEXT DEFAULT 'beklemede',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. İplik Teslimat Kayıtları Tablosu
CREATE TABLE IF NOT EXISTS iplik_teslimat_kayitlari (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  kalem_id UUID NOT NULL REFERENCES iplik_siparis_kalemleri(id) ON DELETE CASCADE,
  teslimat_no TEXT NOT NULL,
  teslimat_tarihi DATE NOT NULL DEFAULT CURRENT_DATE,
  gelen_miktar NUMERIC(10,2) NOT NULL,
  lot_no TEXT,
  notlar TEXT,
  kalite_durumu TEXT DEFAULT 'onaylandi' CHECK (kalite_durumu IN ('onaylandi', 'beklemede', 'sartli_kabul', 'reddedildi')),
  eklenen_kisi TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. İndeksler
CREATE INDEX IF NOT EXISTS idx_siparis_kalemleri_siparis_id ON iplik_siparis_kalemleri(siparis_id);
CREATE INDEX IF NOT EXISTS idx_siparis_kalemleri_kalem_no ON iplik_siparis_kalemleri(kalem_no);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_kalem_id ON iplik_teslimat_kayitlari(kalem_id);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_teslimat_no ON iplik_teslimat_kayitlari(teslimat_no);
CREATE INDEX IF NOT EXISTS idx_teslimat_kayitlari_tarih ON iplik_teslimat_kayitlari(teslimat_tarihi);

-- 6. Trigger'lar updated_at için
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları oluştur
DROP TRIGGER IF EXISTS update_iplik_siparis_kalemleri_updated_at ON iplik_siparis_kalemleri;
CREATE TRIGGER update_iplik_siparis_kalemleri_updated_at 
    BEFORE UPDATE ON iplik_siparis_kalemleri 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_iplik_teslimat_kayitlari_updated_at ON iplik_teslimat_kayitlari;
CREATE TRIGGER update_iplik_teslimat_kayitlari_updated_at 
    BEFORE UPDATE ON iplik_teslimat_kayitlari 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. RLS (Row Level Security) Politikaları
ALTER TABLE iplik_siparis_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE iplik_teslimat_kayitlari ENABLE ROW LEVEL SECURITY;

-- Politikaları oluştur
DO $$
BEGIN
    -- İplik sipariş kalemleri politikaları
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_siparis_kalemleri' AND policyname = 'allow_all_select') THEN
        CREATE POLICY allow_all_select ON iplik_siparis_kalemleri FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_siparis_kalemleri' AND policyname = 'allow_all_insert') THEN
        CREATE POLICY allow_all_insert ON iplik_siparis_kalemleri FOR INSERT WITH CHECK (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_siparis_kalemleri' AND policyname = 'allow_all_update') THEN
        CREATE POLICY allow_all_update ON iplik_siparis_kalemleri FOR UPDATE USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_siparis_kalemleri' AND policyname = 'allow_all_delete') THEN
        CREATE POLICY allow_all_delete ON iplik_siparis_kalemleri FOR DELETE USING (true);
    END IF;

    -- Teslimat kayıtları politikaları
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_teslimat_kayitlari' AND policyname = 'allow_all_select') THEN
        CREATE POLICY allow_all_select ON iplik_teslimat_kayitlari FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_teslimat_kayitlari' AND policyname = 'allow_all_insert') THEN
        CREATE POLICY allow_all_insert ON iplik_teslimat_kayitlari FOR INSERT WITH CHECK (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_teslimat_kayitlari' AND policyname = 'allow_all_update') THEN
        CREATE POLICY allow_all_update ON iplik_teslimat_kayitlari FOR UPDATE USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'iplik_teslimat_kayitlari' AND policyname = 'allow_all_delete') THEN
        CREATE POLICY allow_all_delete ON iplik_teslimat_kayitlari FOR DELETE USING (true);
    END IF;
END $$;

-- 8. Mevcut iplik_stoklari tablosuna eksik kolonlar ekle (eğer yoksa)
DO $$ 
BEGIN
    -- tedarikci_id kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'tedarikci_id') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN tedarikci_id UUID REFERENCES tedarikciler(id);
    END IF;
    
    -- birim kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'birim') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN birim TEXT DEFAULT 'kg';
    END IF;
    
    -- birim_fiyat kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'birim_fiyat') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN birim_fiyat NUMERIC(10,2);
    END IF;
    
    -- para_birimi kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'para_birimi') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN para_birimi TEXT DEFAULT 'TL';
    END IF;
    
    -- toplam_deger kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_stoklari' AND column_name = 'toplam_deger') THEN
        ALTER TABLE iplik_stoklari ADD COLUMN toplam_deger NUMERIC(10,2);
    END IF;
END $$;

-- 9. Mevcut iplik_siparisleri tablosuna eksik kolonlar ekle (eğer yoksa)
DO $$ 
BEGIN
    -- durum kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'durum') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN durum TEXT DEFAULT 'beklemede';
    END IF;
    
    -- teslim_edildi_at kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'teslim_edildi_at') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN teslim_edildi_at TIMESTAMPTZ;
    END IF;
    
    -- birim kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'birim') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN birim TEXT DEFAULT 'kg';
    END IF;
    
    -- birim_fiyat kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'birim_fiyat') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN birim_fiyat NUMERIC(10,2);
    END IF;
    
    -- para_birimi kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'iplik_siparisleri' AND column_name = 'para_birimi') THEN
        ALTER TABLE iplik_siparisleri ADD COLUMN para_birimi TEXT DEFAULT 'TL';
    END IF;
END $$;

-- 10. Mevcut tedarikciler tablosuna eksik kolonlar ekle (eğer yoksa)
DO $$ 
BEGIN
    -- tedarikci_turu kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tedarikciler' AND column_name = 'tedarikci_turu') THEN
        ALTER TABLE tedarikciler ADD COLUMN tedarikci_turu TEXT;
    END IF;
    
    -- faaliyet_alani kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tedarikciler' AND column_name = 'faaliyet_alani') THEN
        ALTER TABLE tedarikciler ADD COLUMN faaliyet_alani TEXT;
    END IF;
    
    -- durum kolonu ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tedarikciler' AND column_name = 'durum') THEN
        ALTER TABLE tedarikciler ADD COLUMN durum TEXT DEFAULT 'aktif';
    END IF;
END $$;

-- Başarı mesajı
SELECT 'İplik teslimat sistemi tabloları başarıyla oluşturuldu! (View olmadan)' as sonuc;
