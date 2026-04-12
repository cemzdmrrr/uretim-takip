-- ============================================================
-- AŞAMA 1.5: NOT NULL CONSTRAINT VE FİNALİZASYON
-- TexPilot SaaS Dönüşümü - Veri Bütünlüğü Güvencesi
-- ============================================================
-- Migrasyon sonrası firma_id kolonlarını NOT NULL yapar.
-- Bu script SADECE 04_data_migration.sql başarılı çalıştıktan sonra çalıştırılmalı.
-- Önce kontrol sorgusu ile firma_id NULL olan kayıt kalmadığından emin olun.
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- KONTROL: firma_id NULL olan kayıt var mı?
-- ─────────────────────────────────────────────────────────

DO $$
DECLARE
    tablo_adi TEXT;
    null_count BIGINT;
    has_nulls BOOLEAN := false;
BEGIN
    FOR tablo_adi IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'firma_id'
        AND table_schema = 'public'
        AND udt_name = 'uuid'  -- Sadece UUID tipindeki firma_id kolonlari
        AND table_name NOT IN (
            'firmalar', 'firma_kullanicilari', 'kullanici_aktif_firma',
            'firma_davetleri', 'firma_ayarlari', 'firma_modulleri',
            'firma_uretim_modulleri', 'firma_abonelikleri', 'abonelik_odemeleri',
            'modul_tanimlari', 'uretim_modulleri', 'abonelik_planlari',
            'yetki_tanimlari'
        )
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE firma_id IS NULL', tablo_adi) INTO null_count;
        IF null_count > 0 THEN
            RAISE WARNING '⚠️ %: % kayıtta firma_id NULL!', tablo_adi, null_count;
            has_nulls := true;
        END IF;
    END LOOP;

    IF has_nulls THEN
        RAISE EXCEPTION '❌ Bazı tablolarda firma_id NULL olan kayıtlar var! Önce 04_data_migration.sql çalıştırın.';
    ELSE
        RAISE NOTICE '✅ Tüm tablolarda firma_id dolu. NOT NULL constraint eklenebilir.';
    END IF;
END $$;

-- ─────────────────────────────────────────────────────────
-- NOT NULL CONSTRAINT EKLEME (DİNAMİK)
-- Sadece mevcut olan ve firma_id kolonu bulunan tablolara uygulanır
-- ─────────────────────────────────────────────────────────

DO $$
DECLARE
    tablo_adi TEXT;
BEGIN
    FOR tablo_adi IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'firma_id'
        AND table_schema = 'public'
        AND udt_name = 'uuid'  -- Sadece UUID tipindeki firma_id kolonlari
        AND table_name NOT IN (
            'firmalar', 'firma_kullanicilari', 'kullanici_aktif_firma',
            'firma_davetleri', 'firma_ayarlari', 'firma_modulleri',
            'firma_uretim_modulleri', 'firma_abonelikleri', 'abonelik_odemeleri',
            'modul_tanimlari', 'uretim_modulleri', 'abonelik_planlari',
            'yetki_tanimlari'
        )
    LOOP
        EXECUTE format('ALTER TABLE %I ALTER COLUMN firma_id SET NOT NULL', tablo_adi);
        RAISE NOTICE 'NOT NULL eklendi: %', tablo_adi;
    END LOOP;
END $$;

DO $$ BEGIN RAISE NOTICE '✅ Aşama 1.5 tamamlandı: Tüm tablolara NOT NULL constraint eklendi.'; END $$;
