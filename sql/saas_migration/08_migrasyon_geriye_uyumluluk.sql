-- ============================================================
-- AŞAMA 10: VERİ MİGRASYONU & GERİYE UYUMLULUK
-- TexPilot SaaS Dönüşümü - Backward Compatibility & Validation
-- ============================================================
-- Bu script:
-- 1. Legacy atama tablolarından genel uretim_atamalari tablosuna veri kopyalar
-- 2. Geriye uyumluluk view'ları oluşturur
-- 3. Migrasyon doğrulama fonksiyonları ekler
-- 4. Migrasyon durumu tablosu oluşturur
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- 1. MİGRASYON DURUMU TABLOSU
-- ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS migrasyon_durumu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    adim_kodu VARCHAR(100) NOT NULL UNIQUE,
    adim_adi VARCHAR(200) NOT NULL,
    durum VARCHAR(30) NOT NULL DEFAULT 'beklemede'
        CHECK (durum IN ('beklemede','baslatildi','tamamlandi','hata','atlandi')),
    baslama_zamani TIMESTAMPTZ,
    bitis_zamani TIMESTAMPTZ,
    islem_sayisi INT DEFAULT 0,
    hata_mesaji TEXT,
    detaylar JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 2. MİGRASYON DOĞRULAMA FONKSİYONLARI
-- ─────────────────────────────────────────────────────────

-- Firma_id NULL olan kayıtları raporla
CREATE OR REPLACE FUNCTION migrasyon_firma_id_kontrol()
RETURNS TABLE(tablo_adi TEXT, null_kayit_sayisi BIGINT, toplam_kayit BIGINT) AS $$
DECLARE
    t TEXT;
    nc BIGINT;
    tc BIGINT;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'firma_id' AND table_schema = 'public' AND udt_name = 'uuid'
        AND table_name NOT IN (
            'firmalar', 'firma_kullanicilari', 'kullanici_aktif_firma',
            'firma_davetleri', 'firma_ayarlari', 'firma_modulleri',
            'firma_uretim_modulleri', 'firma_abonelikleri', 'abonelik_odemeleri',
            'modul_tanimlari', 'uretim_modulleri', 'abonelik_planlari',
            'yetki_tanimlari', 'migrasyon_durumu', 'destek_talepleri',
            'platform_loglari', 'platform_duyurulari'
        )
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE firma_id IS NULL', t) INTO nc;
        EXECUTE format('SELECT COUNT(*) FROM %I', t) INTO tc;
        IF nc > 0 OR tc > 0 THEN
            tablo_adi := t;
            null_kayit_sayisi := nc;
            toplam_kayit := tc;
            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS aktif mi kontrol fonksiyonu
CREATE OR REPLACE FUNCTION migrasyon_rls_kontrol()
RETURNS TABLE(tablo_adi TEXT, rls_aktif BOOLEAN) AS $$
BEGIN
    FOR tablo_adi, rls_aktif IN
        SELECT c.relname::TEXT, c.relrowsecurity
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public'
        AND c.relkind = 'r'
        AND c.relname IN (
            SELECT table_name FROM information_schema.columns
            WHERE column_name = 'firma_id' AND table_schema = 'public' AND udt_name = 'uuid'
        )
        ORDER BY c.relname
    LOOP
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Genel migrasyon sağlık raporu
CREATE OR REPLACE FUNCTION migrasyon_saglik_raporu()
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_firma_count INT;
    v_user_count INT;
    v_null_firma_id_tables INT;
    v_tables_without_rls INT;
    v_orphan_users INT;
    v_missing_abonelik INT;
BEGIN
    -- Toplam firma sayısı
    SELECT COUNT(*) INTO v_firma_count FROM firmalar WHERE aktif = true;

    -- Toplam kullanıcı sayısı
    SELECT COUNT(DISTINCT user_id) INTO v_user_count FROM firma_kullanicilari WHERE aktif = true;

    -- firma_id NULL olan tablo sayısı
    SELECT COUNT(*) INTO v_null_firma_id_tables
    FROM migrasyon_firma_id_kontrol() WHERE null_kayit_sayisi > 0;

    -- RLS aktif olmayan tablo sayısı
    SELECT COUNT(*) INTO v_tables_without_rls
    FROM migrasyon_rls_kontrol() WHERE rls_aktif = false;

    -- Firmaya atanmamış kullanıcılar
    SELECT COUNT(*) INTO v_orphan_users
    FROM auth.users u
    WHERE NOT EXISTS (
        SELECT 1 FROM firma_kullanicilari fk WHERE fk.user_id = u.id
    );

    -- Aboneliği olmayan aktif firmalar
    SELECT COUNT(*) INTO v_missing_abonelik
    FROM firmalar f
    WHERE f.aktif = true AND NOT EXISTS (
        SELECT 1 FROM firma_abonelikleri fa
        WHERE fa.firma_id = f.id AND fa.durum IN ('aktif', 'deneme')
    );

    v_result := jsonb_build_object(
        'tarih', NOW(),
        'aktif_firma_sayisi', v_firma_count,
        'aktif_kullanici_sayisi', v_user_count,
        'null_firma_id_tablo_sayisi', v_null_firma_id_tables,
        'rls_eksik_tablo_sayisi', v_tables_without_rls,
        'firmaya_atanmamis_kullanici', v_orphan_users,
        'aboneligi_olmayan_firma', v_missing_abonelik,
        'saglik_durumu', CASE
            WHEN v_null_firma_id_tables > 0 OR v_tables_without_rls > 0 THEN 'kritik'
            WHEN v_orphan_users > 0 OR v_missing_abonelik > 0 THEN 'uyari'
            ELSE 'saglikli'
        END
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────
-- 3. LEGACY ATAMA VERİLERİNİ GENEL TABLOYA KOPYALA
-- Mevcut 8 atama tablosundaki verileri uretim_atamalari'na aktar
-- ─────────────────────────────────────────────────────────

DO $$
DECLARE
    v_migrated INT := 0;
    v_count INT;
BEGIN
    -- Migrasyon başladı
    INSERT INTO migrasyon_durumu (adim_kodu, adim_adi, durum, baslama_zamani)
    VALUES ('legacy_atama_kopyala', 'Legacy atama tablolarından genel tabloya veri kopyalama', 'baslatildi', NOW())
    ON CONFLICT (adim_kodu) DO UPDATE SET durum = 'baslatildi', baslama_zamani = NOW(), hata_mesaji = NULL;

    BEGIN
        -- Dokuma atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='dokuma_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'dokuma', 1,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM dokuma_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = dokuma_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'dokuma'
                AND ua.firma_id = dokuma_atamalari.firma_id
                AND ua.atanan_kullanici_id = dokuma_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'dokuma_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Konfeksiyon atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='konfeksiyon_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'konfeksiyon', 2,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM konfeksiyon_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = konfeksiyon_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'konfeksiyon'
                AND ua.firma_id = konfeksiyon_atamalari.firma_id
                AND ua.atanan_kullanici_id = konfeksiyon_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'konfeksiyon_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Yıkama atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='yikama_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'yikama', 3,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM yikama_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = yikama_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'yikama'
                AND ua.firma_id = yikama_atamalari.firma_id
                AND ua.atanan_kullanici_id = yikama_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'yikama_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Nakış atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='nakis_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'nakis', 4,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM nakis_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = nakis_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'nakis'
                AND ua.firma_id = nakis_atamalari.firma_id
                AND ua.atanan_kullanici_id = nakis_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'nakis_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- İlik düğme atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='ilik_dugme_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'ilik_dugme', 5,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM ilik_dugme_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = ilik_dugme_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'ilik_dugme'
                AND ua.firma_id = ilik_dugme_atamalari.firma_id
                AND ua.atanan_kullanici_id = ilik_dugme_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'ilik_dugme_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Ütü atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='utu_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'utu', 6,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM utu_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = utu_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'utu'
                AND ua.firma_id = utu_atamalari.firma_id
                AND ua.atanan_kullanici_id = utu_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'utu_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Paketleme atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='paketleme_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'paketleme', 7,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM paketleme_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = paketleme_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'paketleme'
                AND ua.firma_id = paketleme_atamalari.firma_id
                AND ua.atanan_kullanici_id = paketleme_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'paketleme_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Kalite kontrol atamaları
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='kalite_kontrol_atamalari') THEN
            INSERT INTO uretim_atamalari (firma_id, model_id, uretim_dali, asama_kodu, asama_sira_no,
                atanan_email, atanan_kullanici_id, toplam_adet, tamamlanan_adet, fire_adet,
                durum, baslama_tarihi, bitis_tarihi, notlar, created_at)
            SELECT firma_id, model_id, 'triko', 'kalite_kontrol', 8,
                atanan_email, atanan_kullanici_id,
                COALESCE(talep_edilen_adet, adet, 0),
                COALESCE(tamamlanan_adet, 0),
                COALESCE(fire_adet, 0),
                COALESCE(durum, 'atandi'),
                atama_tarihi, tamamlama_tarihi, notlar, COALESCE(created_at, NOW())
            FROM kalite_kontrol_atamalari
            WHERE firma_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM uretim_atamalari ua
                WHERE ua.model_id = kalite_kontrol_atamalari.model_id
                AND ua.uretim_dali = 'triko' AND ua.asama_kodu = 'kalite_kontrol'
                AND ua.firma_id = kalite_kontrol_atamalari.firma_id
                AND ua.atanan_kullanici_id = kalite_kontrol_atamalari.atanan_kullanici_id
            );
            GET DIAGNOSTICS v_count = ROW_COUNT;
            v_migrated := v_migrated + v_count;
            RAISE NOTICE 'kalite_kontrol_atamalari -> uretim_atamalari: % kayit', v_count;
        END IF;

        -- Başarılı
        UPDATE migrasyon_durumu SET
            durum = 'tamamlandi', bitis_zamani = NOW(), islem_sayisi = v_migrated,
            detaylar = jsonb_build_object('toplam_kopyalanan', v_migrated)
        WHERE adim_kodu = 'legacy_atama_kopyala';

        RAISE NOTICE '✅ Legacy atama kopyalama tamamlandı: % kayıt', v_migrated;

    EXCEPTION WHEN OTHERS THEN
        UPDATE migrasyon_durumu SET
            durum = 'hata', bitis_zamani = NOW(), hata_mesaji = SQLERRM
        WHERE adim_kodu = 'legacy_atama_kopyala';
        RAISE NOTICE '❌ Legacy atama kopyalama hatası: %', SQLERRM;
    END;
END $$;

-- ─────────────────────────────────────────────────────────
-- 4. GERİYE UYUMLULUK VIEW'LARI
-- Eski atama tablosu adları ile uretim_atamalari'na erişim
-- Bu view'lar mevcut kodu kırmadan geçiş sağlar
-- ─────────────────────────────────────────────────────────

-- NOT: Legacy tablolar hala mevcut, bu view'lar yeni kodun
-- genel tabloyu kullanmasını sağlar. İleride tablolar
-- kaldırıldığında bu view'lar aktif olacak.

-- Geriye uyumluluk: sirket_bilgileri → firmalar
CREATE OR REPLACE VIEW v_sirket_bilgileri AS
SELECT
    f.id,
    f.firma_adi AS sirket_adi,
    f.vergi_no,
    f.vergi_dairesi,
    f.adres,
    f.telefon,
    f.email,
    f.logo_url,
    f.aktif,
    f.created_at,
    f.updated_at
FROM firmalar f
WHERE f.id = get_active_firma_id() OR is_platform_admin();

-- Geriye uyumluluk: Dokuma atamaları view (uretim_atamalari üzerinden)
CREATE OR REPLACE VIEW v_compat_dokuma_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'dokuma';

-- Geriye uyumluluk: Konfeksiyon atamaları view
CREATE OR REPLACE VIEW v_compat_konfeksiyon_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'konfeksiyon';

-- Geriye uyumluluk: Yıkama atamaları view
CREATE OR REPLACE VIEW v_compat_yikama_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'yikama';

-- Geriye uyumluluk: Nakış atamaları view
CREATE OR REPLACE VIEW v_compat_nakis_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'nakis';

-- Geriye uyumluluk: İlik düğme atamaları view
CREATE OR REPLACE VIEW v_compat_ilik_dugme_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'ilik_dugme';

-- Geriye uyumluluk: Ütü atamaları view
CREATE OR REPLACE VIEW v_compat_utu_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'utu';

-- Geriye uyumluluk: Paketleme atamaları view
CREATE OR REPLACE VIEW v_compat_paketleme_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'paketleme';

-- Geriye uyumluluk: Kalite kontrol atamaları view
CREATE OR REPLACE VIEW v_compat_kalite_kontrol_atamalari AS
SELECT
    ua.id, ua.firma_id, ua.model_id,
    ua.atanan_email, ua.atanan_kullanici_id,
    ua.toplam_adet AS adet,
    ua.toplam_adet AS talep_edilen_adet,
    ua.tamamlanan_adet,
    ua.fire_adet,
    ua.durum,
    ua.baslama_tarihi AS atama_tarihi,
    ua.bitis_tarihi AS tamamlama_tarihi,
    ua.notlar,
    ua.created_at, ua.updated_at
FROM uretim_atamalari ua
WHERE ua.uretim_dali = 'triko' AND ua.asama_kodu = 'kalite_kontrol';

-- ─────────────────────────────────────────────────────────
-- 5. MİGRASYON ADIMLARI KAYIT
-- ─────────────────────────────────────────────────────────

INSERT INTO migrasyon_durumu (adim_kodu, adim_adi, durum, bitis_zamani) VALUES
    ('01_tenant_core', 'Tenant çekirdek tablolar', 'tamamlandi', NOW()),
    ('02_firma_id_kolon', 'firma_id kolon ekleme', 'tamamlandi', NOW()),
    ('03_rls_policies', 'RLS politikaları', 'tamamlandi', NOW()),
    ('04_data_migration', 'Veri migrasyonu', 'tamamlandi', NOW()),
    ('05_not_null', 'NOT NULL constraint', 'tamamlandi', NOW()),
    ('06_uretim_genel', 'Üretim genelleştirme', 'tamamlandi', NOW()),
    ('07_platform_admin', 'Platform admin altyapısı', 'tamamlandi', NOW()),
    ('08_backward_compat', 'Geriye uyumluluk view''ları', 'tamamlandi', NOW()),
    ('09_firma_id_fix', 'Uygulama tarafı firma_id düzeltmeleri', 'tamamlandi', NOW())
ON CONFLICT (adim_kodu) DO NOTHING;

DO $$ BEGIN RAISE NOTICE '✅ Aşama 10 tamamlandı: Geriye uyumluluk view''ları, migrasyon doğrulama ve legacy veri kopyalama.'; END $$;
