-- ============================================================
-- ASAMA 1.2: MEVCUT TABLOLARA firma_id KOLONU EKLEME
-- TexPilot SaaS Donusumu - Veri Izolasyonu Altyapisi
-- ============================================================
-- Bu script mevcut tablolara firma_id kolonu ekler.
-- Ilk etapta NULLABLE olarak eklenir, migrasyon sonrasi NOT NULL yapilir.
-- Mevcut olmayan tablolar otomatik olarak atlanir.
-- ============================================================

-- ---------------------------------------------------------
-- YARDIMCI FONKSIYONLAR (script sonunda temizlenir)
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION _saas_add_firma_id(p_table TEXT) RETURNS VOID AS $$
DECLARE
    v_data_type TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=p_table) THEN
        RAISE NOTICE 'Tablo mevcut degil, atlaniyor: %', p_table;
        RETURN;
    END IF;
    -- firma_id kolonu var mi kontrol et
    SELECT data_type INTO v_data_type
    FROM information_schema.columns
    WHERE table_schema='public' AND table_name=p_table AND column_name='firma_id';

    IF v_data_type IS NULL THEN
        -- Kolon yok, ekle
        EXECUTE format('ALTER TABLE public.%I ADD COLUMN firma_id UUID REFERENCES firmalar(id) ON DELETE CASCADE', p_table);
        RAISE NOTICE 'firma_id (UUID) eklendi: %', p_table;
    ELSIF v_data_type != 'uuid' THEN
        -- Mevcut kolon UUID degil (ornegin integer), yeniden adlandir ve yeni UUID ekle
        EXECUTE format('ALTER TABLE public.%I RENAME COLUMN firma_id TO eski_firma_id', p_table);
        EXECUTE format('ALTER TABLE public.%I ADD COLUMN firma_id UUID REFERENCES firmalar(id) ON DELETE CASCADE', p_table);
        RAISE NOTICE 'Eski firma_id (%) -> eski_firma_id olarak yeniden adlandi, yeni UUID firma_id eklendi: %', v_data_type, p_table;
    ELSE
        RAISE NOTICE 'firma_id (UUID) zaten mevcut: %', p_table;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _saas_create_firma_index(p_table TEXT) RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=p_table) THEN
        RETURN;
    END IF;
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_firma ON public.%I(firma_id)', p_table, p_table);
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------
-- FAZA 1: firma_id KOLONU EKLEME (NULLABLE)
-- ---------------------------------------------------------

-- Model & Uretim
SELECT _saas_add_firma_id('triko_takip');
SELECT _saas_add_firma_id('modeller');
SELECT _saas_add_firma_id('uretim_kayitlari');
SELECT _saas_add_firma_id('model_kritikleri');
-- model_toplam_adetler bir VIEW oldugu icin atlandi

-- Beden Yonetimi
SELECT _saas_add_firma_id('beden_tanimlari');
SELECT _saas_add_firma_id('model_beden_dagilimi');
-- model_beden_ozet bir VIEW oldugu icin atlandi
SELECT _saas_add_firma_id('dokuma_beden_takip');

-- Atama Tablolari
SELECT _saas_add_firma_id('dokuma_atamalari');
SELECT _saas_add_firma_id('konfeksiyon_atamalari');
SELECT _saas_add_firma_id('kalite_kontrol_atamalari');
SELECT _saas_add_firma_id('paketleme_atamalari');
SELECT _saas_add_firma_id('utu_atamalari');
SELECT _saas_add_firma_id('yikama_atamalari');
SELECT _saas_add_firma_id('nakis_atamalari');
SELECT _saas_add_firma_id('ilik_dugme_atamalari');

-- Iplik & Stok
SELECT _saas_add_firma_id('iplik_stoklari');
SELECT _saas_add_firma_id('iplik_hareketleri');
SELECT _saas_add_firma_id('iplik_siparisleri');
SELECT _saas_add_firma_id('iplik_stok_hareketleri');
SELECT _saas_add_firma_id('stok_hareketleri');

-- Aksesuar
SELECT _saas_add_firma_id('aksesuarlar');
SELECT _saas_add_firma_id('aksesuar_stok');
SELECT _saas_add_firma_id('aksesuar_kullanim');
SELECT _saas_add_firma_id('aksesuar_bedenler');
SELECT _saas_add_firma_id('model_aksesuar');

-- Finans
SELECT _saas_add_firma_id('faturalar');
SELECT _saas_add_firma_id('fatura_kalemleri');
SELECT _saas_add_firma_id('kasa_banka_hesaplari');
SELECT _saas_add_firma_id('kasa_banka_hareketleri');
SELECT _saas_add_firma_id('odeme_kayitlari');
SELECT _saas_add_firma_id('odeme_gecmisi');
SELECT _saas_add_firma_id('maliyet_hesaplama');
SELECT _saas_add_firma_id('donemler');

-- Tedarikci
SELECT _saas_add_firma_id('tedarikciler');
SELECT _saas_add_firma_id('tedarikci_siparisleri');
SELECT _saas_add_firma_id('tedarikci_odemeleri');

-- Musteri
SELECT _saas_add_firma_id('musteriler');

-- Sevkiyat
SELECT _saas_add_firma_id('sevkiyat_kayitlari');
SELECT _saas_add_firma_id('sevkiyat_detaylari');
SELECT _saas_add_firma_id('sevk_talepleri');
SELECT _saas_add_firma_id('ceki_listesi');
SELECT _saas_add_firma_id('yukleme_kayitlari');

-- Personel & IK
SELECT _saas_add_firma_id('personel');
SELECT _saas_add_firma_id('personel_donem');
SELECT _saas_add_firma_id('bordro');
SELECT _saas_add_firma_id('mesai');
SELECT _saas_add_firma_id('mesai_kayitlari');
SELECT _saas_add_firma_id('puantaj');
SELECT _saas_add_firma_id('izinler');
SELECT _saas_add_firma_id('izin_kayitlari');

-- Sistem & Organizasyon
SELECT _saas_add_firma_id('atolyeler');
SELECT _saas_add_firma_id('bildirimler');
SELECT _saas_add_firma_id('dosyalar');
SELECT _saas_add_firma_id('teknik_dosyalar');
SELECT _saas_add_firma_id('urun_depo');

-- ---------------------------------------------------------
-- FAZA 2: INDEKSLER
-- firma_id uzerinden hizli filtreleme icin indexler
-- ---------------------------------------------------------

SELECT _saas_create_firma_index('triko_takip');
SELECT _saas_create_firma_index('modeller');
SELECT _saas_create_firma_index('uretim_kayitlari');
SELECT _saas_create_firma_index('model_kritikleri');
SELECT _saas_create_firma_index('beden_tanimlari');
SELECT _saas_create_firma_index('model_beden_dagilimi');
SELECT _saas_create_firma_index('dokuma_beden_takip');
SELECT _saas_create_firma_index('dokuma_atamalari');
SELECT _saas_create_firma_index('konfeksiyon_atamalari');
SELECT _saas_create_firma_index('kalite_kontrol_atamalari');
SELECT _saas_create_firma_index('paketleme_atamalari');
SELECT _saas_create_firma_index('utu_atamalari');
SELECT _saas_create_firma_index('yikama_atamalari');
SELECT _saas_create_firma_index('nakis_atamalari');
SELECT _saas_create_firma_index('ilik_dugme_atamalari');
SELECT _saas_create_firma_index('iplik_stoklari');
SELECT _saas_create_firma_index('iplik_hareketleri');
SELECT _saas_create_firma_index('iplik_siparisleri');
SELECT _saas_create_firma_index('iplik_stok_hareketleri');
SELECT _saas_create_firma_index('stok_hareketleri');
SELECT _saas_create_firma_index('aksesuarlar');
SELECT _saas_create_firma_index('aksesuar_stok');
SELECT _saas_create_firma_index('aksesuar_kullanim');
SELECT _saas_create_firma_index('aksesuar_bedenler');
SELECT _saas_create_firma_index('model_aksesuar');
SELECT _saas_create_firma_index('faturalar');
SELECT _saas_create_firma_index('fatura_kalemleri');
SELECT _saas_create_firma_index('kasa_banka_hesaplari');
SELECT _saas_create_firma_index('kasa_banka_hareketleri');
SELECT _saas_create_firma_index('odeme_kayitlari');
SELECT _saas_create_firma_index('odeme_gecmisi');
SELECT _saas_create_firma_index('maliyet_hesaplama');
SELECT _saas_create_firma_index('donemler');
SELECT _saas_create_firma_index('tedarikciler');
SELECT _saas_create_firma_index('tedarikci_siparisleri');
SELECT _saas_create_firma_index('tedarikci_odemeleri');
SELECT _saas_create_firma_index('musteriler');
SELECT _saas_create_firma_index('sevkiyat_kayitlari');
SELECT _saas_create_firma_index('sevkiyat_detaylari');
SELECT _saas_create_firma_index('sevk_talepleri');
SELECT _saas_create_firma_index('ceki_listesi');
SELECT _saas_create_firma_index('yukleme_kayitlari');
SELECT _saas_create_firma_index('personel');
SELECT _saas_create_firma_index('personel_donem');
SELECT _saas_create_firma_index('bordro');
SELECT _saas_create_firma_index('mesai');
SELECT _saas_create_firma_index('mesai_kayitlari');
SELECT _saas_create_firma_index('puantaj');
SELECT _saas_create_firma_index('izinler');
SELECT _saas_create_firma_index('izin_kayitlari');
SELECT _saas_create_firma_index('atolyeler');
SELECT _saas_create_firma_index('bildirimler');
SELECT _saas_create_firma_index('dosyalar');
SELECT _saas_create_firma_index('teknik_dosyalar');
SELECT _saas_create_firma_index('urun_depo');

-- ---------------------------------------------------------
-- TEMIZLIK: Yardimci fonksiyonlari kaldir
-- ---------------------------------------------------------
DROP FUNCTION IF EXISTS _saas_add_firma_id(TEXT);
DROP FUNCTION IF EXISTS _saas_create_firma_index(TEXT);

DO $$ BEGIN RAISE NOTICE 'Asama 1.2 tamamlandi: Mevcut tablolara firma_id kolonu ve indeksler eklendi (mevcut olmayan tablolar atlandi).'; END $$;
