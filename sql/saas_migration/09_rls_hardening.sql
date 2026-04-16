-- ============================================================
-- AŞAMA 1.6: RLS HARDENING / ACTIVE FIRMA GÜVENLİĞİ
-- TexPilot SaaS Dönüşümü - Tenant izolasyonunu sıkılaştırır
-- ============================================================
-- Amaçlar:
-- 1. Aktif firma seçimini server-side doğrulamak
-- 2. Kritik iş tablolarında firma_id IS NULL boşluğunu kapatmak
-- 3. İstemci filtrelerini güvenlik değil UX/performance katmanı haline getirmek
-- 4. Eksik firma_id kayıtlarını raporlayacak audit fonksiyonu eklemek
-- ============================================================

-- ------------------------------------------------------------
-- HELPER FONKSİYONLAR
-- ------------------------------------------------------------

-- Kullanıcının ilgili firmaya aktif erişimi var mı?
CREATE OR REPLACE FUNCTION has_firma_access(p_firma_id UUID)
RETURNS BOOLEAN AS $$
    SELECT
        p_firma_id IS NOT NULL
        AND (
            is_platform_admin()
            OR EXISTS (
                SELECT 1
                FROM firma_kullanicilari
                WHERE firma_id = p_firma_id
                  AND user_id = auth.uid()
                  AND aktif = true
            )
        );
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Kullanıcı ilgili firmayı yönetebilir mi?
CREATE OR REPLACE FUNCTION can_manage_firma(p_firma_id UUID)
RETURNS BOOLEAN AS $$
    SELECT
        p_firma_id IS NOT NULL
        AND (
            is_platform_admin()
            OR EXISTS (
                SELECT 1
                FROM firma_kullanicilari
                WHERE firma_id = p_firma_id
                  AND user_id = auth.uid()
                  AND aktif = true
                  AND rol IN ('firma_sahibi', 'firma_admin')
            )
        );
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Mevcut kullanıcının JWT e-postasını döndürür.
CREATE OR REPLACE FUNCTION current_user_email()
RETURNS TEXT AS $$
    SELECT NULLIF(lower(coalesce(auth.jwt() ->> 'email', '')), '');
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Kullanıcının erişebildiği firma ID'lerini güvenli biçimde döndürür.
CREATE OR REPLACE FUNCTION get_user_firma_ids()
RETURNS SETOF UUID AS $$
    SELECT DISTINCT fk.firma_id
    FROM firma_kullanicilari fk
    WHERE fk.user_id = auth.uid()
      AND fk.aktif = true
    UNION
    SELECT kaf.firma_id
    FROM kullanici_aktif_firma kaf
    WHERE kaf.user_id = auth.uid()
      AND has_firma_access(kaf.firma_id);
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Aktif firma ID'sini sadece erişim doğrulandıysa döndürür.
CREATE OR REPLACE FUNCTION get_active_firma_id()
RETURNS UUID AS $$
    SELECT kaf.firma_id
    FROM kullanici_aktif_firma kaf
    WHERE kaf.user_id = auth.uid()
      AND has_firma_access(kaf.firma_id)
    ORDER BY kaf.son_giris DESC NULLS LAST
    LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- İş tabloları için aktif firma eşleşmesi helper'ı.
CREATE OR REPLACE FUNCTION active_firma_match(p_firma_id UUID)
RETURNS BOOLEAN AS $$
    SELECT
        p_firma_id IS NOT NULL
        AND (
            is_platform_admin()
            OR p_firma_id = get_active_firma_id()
        );
$$ LANGUAGE SQL SECURITY DEFINER STABLE SET search_path = public;

-- Aktif firma seçimini doğrulayarak yazar.
DROP FUNCTION IF EXISTS set_active_firma(UUID);

CREATE OR REPLACE FUNCTION set_active_firma(p_firma_id UUID)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Oturum açık değil';
    END IF;

    IF p_firma_id IS NULL THEN
        RAISE EXCEPTION 'Firma ID zorunlu';
    END IF;

    IF NOT has_firma_access(p_firma_id) THEN
        RAISE EXCEPTION 'Bu firmaya erişiminiz yok: %', p_firma_id;
    END IF;

    INSERT INTO kullanici_aktif_firma (user_id, firma_id, son_giris)
    VALUES (v_user_id, p_firma_id, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        firma_id = EXCLUDED.firma_id,
        son_giris = NOW();

    RETURN p_firma_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION has_firma_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION has_firma_access(UUID) TO authenticated;

REVOKE ALL ON FUNCTION can_manage_firma(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION can_manage_firma(UUID) TO authenticated;

REVOKE ALL ON FUNCTION current_user_email() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION current_user_email() TO authenticated;

REVOKE ALL ON FUNCTION get_user_firma_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_user_firma_ids() TO authenticated;

REVOKE ALL ON FUNCTION get_active_firma_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_active_firma_id() TO authenticated;

REVOKE ALL ON FUNCTION active_firma_match(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION active_firma_match(UUID) TO authenticated;

REVOKE ALL ON FUNCTION set_active_firma(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION set_active_firma(UUID) TO authenticated;

-- Kritik tablolarda eksik firma_id audit fonksiyonu.
DROP FUNCTION IF EXISTS tenant_missing_firma_id_report();

CREATE OR REPLACE FUNCTION tenant_missing_firma_id_report()
RETURNS TABLE (
    table_name TEXT,
    total_count BIGINT,
    missing_firma_id_count BIGINT
) AS $$
DECLARE
    v_table_name TEXT;
    v_tables TEXT[] := ARRAY[
        'triko_takip',
        'modeller',
        'uretim_kayitlari',
        'dokuma_atamalari',
        'konfeksiyon_atamalari',
        'kalite_kontrol_atamalari',
        'paketleme_atamalari',
        'utu_atamalari',
        'yikama_atamalari',
        'nakis_atamalari',
        'ilik_dugme_atamalari',
        'iplik_stoklari',
        'iplik_hareketleri',
        'aksesuarlar',
        'aksesuar_stok',
        'faturalar',
        'fatura_kalemleri',
        'kasa_banka_hesaplari',
        'kasa_banka_hareketleri',
        'musteriler',
        'tedarikciler',
        'sevkiyat_kayitlari',
        'sevkiyat_detaylari',
        'personel',
        'bordro',
        'mesai',
        'puantaj',
        'izinler',
        'bildirimler',
        'dosyalar',
        'teknik_dosyalar',
        'urun_depo',
        'donemler'
    ];
BEGIN
    FOREACH v_table_name IN ARRAY v_tables LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = v_table_name
              AND column_name = 'firma_id'
        ) THEN
            RETURN QUERY EXECUTE format(
                'SELECT %L::text, COUNT(*)::bigint, COUNT(*) FILTER (WHERE firma_id IS NULL)::bigint FROM %I',
                v_table_name,
                v_table_name
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION tenant_missing_firma_id_report() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION tenant_missing_firma_id_report() TO authenticated;

-- ------------------------------------------------------------
-- RLS POLICY HARDENING
-- ------------------------------------------------------------

DO $$
DECLARE
    v_policy RECORD;
    v_table_name TEXT;
    v_active_firma_tables TEXT[] := ARRAY[
        'triko_takip',
        'modeller',
        'uretim_kayitlari',
        'model_kritikleri',
        'model_toplam_adetler',
        'beden_tanimlari',
        'model_beden_dagilimi',
        'model_aksesuar',
        'dokuma_atamalari',
        'konfeksiyon_atamalari',
        'kalite_kontrol_atamalari',
        'paketleme_atamalari',
        'utu_atamalari',
        'yikama_atamalari',
        'nakis_atamalari',
        'ilik_dugme_atamalari',
        'iplik_stoklari',
        'iplik_hareketleri',
        'iplik_siparisleri',
        'stok_hareketleri',
        'aksesuarlar',
        'aksesuar_stok',
        'aksesuar_kullanim',
        'aksesuar_bedenler',
        'faturalar',
        'fatura_kalemleri',
        'kasa_banka_hesaplari',
        'kasa_banka_hareketleri',
        'odeme_kayitlari',
        'musteriler',
        'tedarikciler',
        'tedarikci_siparisleri',
        'tedarikci_odemeleri',
        'sevkiyat_kayitlari',
        'sevkiyat_detaylari',
        'sevk_talepleri',
        'ceki_listesi',
        'yukleme_kayitlari',
        'personel',
        'bordro',
        'mesai',
        'puantaj',
        'izinler',
        'bildirimler',
        'dosyalar',
        'teknik_dosyalar',
        'urun_depo',
        'donemler',
        'sistem_ayarlari',
        'atolyeler'
    ];
BEGIN
    -- firmalar
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'firmalar') THEN
        FOR v_policy IN
            SELECT policyname FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'firmalar'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON firmalar', v_policy.policyname);
        END LOOP;

        ALTER TABLE firmalar ENABLE ROW LEVEL SECURITY;
        ALTER TABLE firmalar FORCE ROW LEVEL SECURITY;

        CREATE POLICY firmalar_select ON firmalar
            FOR SELECT
            USING (has_firma_access(id) OR is_platform_admin());

        CREATE POLICY firmalar_insert ON firmalar
            FOR INSERT
            WITH CHECK (is_platform_admin());

        CREATE POLICY firmalar_update ON firmalar
            FOR UPDATE
            USING (can_manage_firma(id) OR is_platform_admin())
            WITH CHECK (can_manage_firma(id) OR is_platform_admin());

        CREATE POLICY firmalar_delete ON firmalar
            FOR DELETE
            USING (is_platform_admin());
    END IF;

    -- firma_kullanicilari
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'firma_kullanicilari') THEN
        FOR v_policy IN
            SELECT policyname FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'firma_kullanicilari'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON firma_kullanicilari', v_policy.policyname);
        END LOOP;

        ALTER TABLE firma_kullanicilari ENABLE ROW LEVEL SECURITY;
        ALTER TABLE firma_kullanicilari FORCE ROW LEVEL SECURITY;

        CREATE POLICY firma_kullanicilari_select ON firma_kullanicilari
            FOR SELECT
            USING (
                user_id = auth.uid()
                OR can_manage_firma(firma_id)
                OR is_platform_admin()
            );

        CREATE POLICY firma_kullanicilari_insert ON firma_kullanicilari
            FOR INSERT
            WITH CHECK (can_manage_firma(firma_id) OR is_platform_admin());

        CREATE POLICY firma_kullanicilari_update ON firma_kullanicilari
            FOR UPDATE
            USING (can_manage_firma(firma_id) OR is_platform_admin())
            WITH CHECK (can_manage_firma(firma_id) OR is_platform_admin());

        CREATE POLICY firma_kullanicilari_delete ON firma_kullanicilari
            FOR DELETE
            USING (can_manage_firma(firma_id) OR is_platform_admin());
    END IF;

    -- kullanici_aktif_firma
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'kullanici_aktif_firma') THEN
        FOR v_policy IN
            SELECT policyname FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'kullanici_aktif_firma'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON kullanici_aktif_firma', v_policy.policyname);
        END LOOP;

        ALTER TABLE kullanici_aktif_firma ENABLE ROW LEVEL SECURITY;
        ALTER TABLE kullanici_aktif_firma FORCE ROW LEVEL SECURITY;

        CREATE POLICY kullanici_aktif_firma_select ON kullanici_aktif_firma
            FOR SELECT
            USING (user_id = auth.uid() OR is_platform_admin());

        CREATE POLICY kullanici_aktif_firma_insert ON kullanici_aktif_firma
            FOR INSERT
            WITH CHECK (
                (user_id = auth.uid() AND has_firma_access(firma_id))
                OR is_platform_admin()
            );

        CREATE POLICY kullanici_aktif_firma_update ON kullanici_aktif_firma
            FOR UPDATE
            USING (
                (user_id = auth.uid() AND has_firma_access(firma_id))
                OR is_platform_admin()
            )
            WITH CHECK (
                (user_id = auth.uid() AND has_firma_access(firma_id))
                OR is_platform_admin()
            );

        CREATE POLICY kullanici_aktif_firma_delete ON kullanici_aktif_firma
            FOR DELETE
            USING (user_id = auth.uid() OR is_platform_admin());
    END IF;

    -- Firma yönetim / üyelik tabloları
    FOREACH v_table_name IN ARRAY ARRAY[
        'firma_ayarlari',
        'firma_davetleri',
        'firma_modulleri',
        'firma_uretim_modulleri',
        'firma_abonelikleri',
        'abonelik_odemeleri'
    ] LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = v_table_name
              AND column_name = 'firma_id'
        ) THEN
            FOR v_policy IN
                SELECT policyname FROM pg_policies
                WHERE schemaname = 'public' AND tablename = v_table_name
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON %I', v_policy.policyname, v_table_name);
            END LOOP;

            EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', v_table_name);
            EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', v_table_name);

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR SELECT USING (has_firma_access(firma_id) OR is_platform_admin())',
                'rls_' || v_table_name || '_select',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR INSERT WITH CHECK (can_manage_firma(firma_id) OR is_platform_admin())',
                'rls_' || v_table_name || '_insert',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR UPDATE USING (can_manage_firma(firma_id) OR is_platform_admin()) WITH CHECK (can_manage_firma(firma_id) OR is_platform_admin())',
                'rls_' || v_table_name || '_update',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR DELETE USING (can_manage_firma(firma_id) OR is_platform_admin())',
                'rls_' || v_table_name || '_delete',
                v_table_name
            );
        END IF;
    END LOOP;

    -- yetki_tanimlari: platform varsayılanları firma_id NULL olabilir
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'yetki_tanimlari') THEN
        FOR v_policy IN
            SELECT policyname FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'yetki_tanimlari'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON yetki_tanimlari', v_policy.policyname);
        END LOOP;

        ALTER TABLE yetki_tanimlari ENABLE ROW LEVEL SECURITY;
        ALTER TABLE yetki_tanimlari FORCE ROW LEVEL SECURITY;

        CREATE POLICY yetki_tanimlari_select ON yetki_tanimlari
            FOR SELECT
            USING (
                firma_id IS NULL
                OR has_firma_access(firma_id)
                OR is_platform_admin()
            );

        CREATE POLICY yetki_tanimlari_insert ON yetki_tanimlari
            FOR INSERT
            WITH CHECK (
                (firma_id IS NULL AND is_platform_admin())
                OR can_manage_firma(firma_id)
                OR is_platform_admin()
            );

        CREATE POLICY yetki_tanimlari_update ON yetki_tanimlari
            FOR UPDATE
            USING (
                (firma_id IS NULL AND is_platform_admin())
                OR can_manage_firma(firma_id)
                OR is_platform_admin()
            )
            WITH CHECK (
                (firma_id IS NULL AND is_platform_admin())
                OR can_manage_firma(firma_id)
                OR is_platform_admin()
            );

        CREATE POLICY yetki_tanimlari_delete ON yetki_tanimlari
            FOR DELETE
            USING (
                (firma_id IS NULL AND is_platform_admin())
                OR can_manage_firma(firma_id)
                OR is_platform_admin()
            );
    END IF;

    -- firma_davetleri: davet edilen kullanıcı e-posta ile görebilsin
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'firma_davetleri') THEN
        DROP POLICY IF EXISTS rls_firma_davetleri_select ON firma_davetleri;

        CREATE POLICY rls_firma_davetleri_select ON firma_davetleri
            FOR SELECT
            USING (
                can_manage_firma(firma_id)
                OR (current_user_email() IS NOT NULL AND lower(email) = current_user_email())
                OR is_platform_admin()
            );
    END IF;

    -- Kritik iş tabloları: sadece aktif firma erişsin, NULL firma_id görünmesin
    FOREACH v_table_name IN ARRAY v_active_firma_tables LOOP
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = v_table_name
              AND column_name = 'firma_id'
        ) THEN
            FOR v_policy IN
                SELECT policyname FROM pg_policies
                WHERE schemaname = 'public' AND tablename = v_table_name
            LOOP
                EXECUTE format('DROP POLICY IF EXISTS %I ON %I', v_policy.policyname, v_table_name);
            END LOOP;

            EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', v_table_name);
            EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', v_table_name);

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR SELECT USING (is_platform_admin() OR active_firma_match(firma_id))',
                'rls_' || v_table_name || '_select',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR INSERT WITH CHECK (is_platform_admin() OR active_firma_match(firma_id))',
                'rls_' || v_table_name || '_insert',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR UPDATE USING (is_platform_admin() OR active_firma_match(firma_id)) WITH CHECK (is_platform_admin() OR active_firma_match(firma_id))',
                'rls_' || v_table_name || '_update',
                v_table_name
            );

            EXECUTE format(
                'CREATE POLICY %I ON %I FOR DELETE USING (is_platform_admin() OR active_firma_match(firma_id))',
                'rls_' || v_table_name || '_delete',
                v_table_name
            );
        END IF;
    END LOOP;
END $$;

DO $$ BEGIN
    RAISE NOTICE '✅ Aşama 1.6 tamamlandı: Aktif firma seçimi doğrulandı, kritik iş tablolarında RLS sıkılaştırıldı.';
END $$;
