-- ============================================================
-- AŞAMA 1.3: ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- TexPilot SaaS Dönüşümü - Veri İzolasyonu Güvenliği
-- ============================================================
-- Her tablo için firma bazlı RLS politikası oluşturulur.
-- Kullanıcı sadece kendi firmasının verilerini görebilir/değiştirebilir.
-- Platform admin tüm verilere erişebilir.
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- YENİ TABLOLAR İÇİN RLS
-- ─────────────────────────────────────────────────────────

-- firmalar: Herkes kendi firmasını görebilir, platform admin hepsini
ALTER TABLE firmalar ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firmalar_select" ON firmalar FOR SELECT USING (
    id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

CREATE POLICY "firmalar_insert" ON firmalar FOR INSERT WITH CHECK (true);
-- Firma oluşturma açık, ancak kayıt sonrası firma_kullanicilari ile ilişkilendirilmeli

CREATE POLICY "firmalar_update" ON firmalar FOR UPDATE USING (
    id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

CREATE POLICY "firmalar_delete" ON firmalar FOR DELETE USING (
    is_platform_admin()
);

-- firma_kullanicilari: Kendi firma kullanıcılarını görebilir
ALTER TABLE firma_kullanicilari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_kullanicilari_select" ON firma_kullanicilari FOR SELECT USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR user_id = auth.uid()
    OR is_platform_admin()
);

CREATE POLICY "firma_kullanicilari_insert" ON firma_kullanicilari FOR INSERT WITH CHECK (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

CREATE POLICY "firma_kullanicilari_update" ON firma_kullanicilari FOR UPDATE USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

CREATE POLICY "firma_kullanicilari_delete" ON firma_kullanicilari FOR DELETE USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- kullanici_aktif_firma: Sadece kendi kaydını görebilir
ALTER TABLE kullanici_aktif_firma ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kullanici_aktif_firma_all" ON kullanici_aktif_firma USING (
    user_id = auth.uid() OR is_platform_admin()
);

-- firma_davetleri
ALTER TABLE firma_davetleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_davetleri_select" ON firma_davetleri FOR SELECT USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
    OR is_platform_admin()
);

CREATE POLICY "firma_davetleri_insert" ON firma_davetleri FOR INSERT WITH CHECK (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- firma_ayarlari
ALTER TABLE firma_ayarlari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_ayarlari_all" ON firma_ayarlari USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- firma_modulleri
ALTER TABLE firma_modulleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_modulleri_all" ON firma_modulleri USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- firma_uretim_modulleri
ALTER TABLE firma_uretim_modulleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_uretim_modulleri_all" ON firma_uretim_modulleri USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- firma_abonelikleri
ALTER TABLE firma_abonelikleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firma_abonelikleri_all" ON firma_abonelikleri USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- abonelik_odemeleri
ALTER TABLE abonelik_odemeleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "abonelik_odemeleri_all" ON abonelik_odemeleri USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- modul_tanimlari: Herkes okuyabilir (platform verileri)
ALTER TABLE modul_tanimlari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "modul_tanimlari_select" ON modul_tanimlari FOR SELECT USING (true);
CREATE POLICY "modul_tanimlari_modify" ON modul_tanimlari FOR ALL USING (is_platform_admin());

-- uretim_modulleri: Herkes okuyabilir (platform verileri)
ALTER TABLE uretim_modulleri ENABLE ROW LEVEL SECURITY;

CREATE POLICY "uretim_modulleri_select" ON uretim_modulleri FOR SELECT USING (true);
CREATE POLICY "uretim_modulleri_modify" ON uretim_modulleri FOR ALL USING (is_platform_admin());

-- abonelik_planlari: Herkes okuyabilir
ALTER TABLE abonelik_planlari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "abonelik_planlari_select" ON abonelik_planlari FOR SELECT USING (true);
CREATE POLICY "abonelik_planlari_modify" ON abonelik_planlari FOR ALL USING (is_platform_admin());

-- yetki_tanimlari: Firma kendi yetkilerini görebilir + platform varsayılanları
ALTER TABLE yetki_tanimlari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "yetki_tanimlari_select" ON yetki_tanimlari FOR SELECT USING (
    firma_id IS NULL  -- platform varsayılanları
    OR firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

CREATE POLICY "yetki_tanimlari_modify" ON yetki_tanimlari FOR ALL USING (
    firma_id IN (SELECT get_user_firma_ids())
    OR is_platform_admin()
);

-- ─────────────────────────────────────────────────────────
-- MEVCUT TABLOLAR İÇİN RLS
-- Genel pattern: firma_id bazlı erişim kontrolü
-- ─────────────────────────────────────────────────────────

-- Dinamik olarak tüm firma_id'li tablolara RLS ekleyen fonksiyon
-- Her tablo için aynı pattern uygulanır

DO $$
DECLARE
    tablo_adi TEXT;
    policy_name TEXT;
BEGIN
    -- firma_id kolonu olan tüm tabloların listesi
    FOR tablo_adi IN
        SELECT table_name FROM information_schema.columns
        WHERE column_name = 'firma_id'
        AND table_schema = 'public'
        AND udt_name = 'uuid'  -- Sadece UUID tipindeki firma_id kolonlari
        AND table_name NOT IN (
            -- Zaten yukarıda RLS tanımlananlar
            'firmalar', 'firma_kullanicilari', 'kullanici_aktif_firma',
            'firma_davetleri', 'firma_ayarlari', 'firma_modulleri',
            'firma_uretim_modulleri', 'firma_abonelikleri', 'abonelik_odemeleri',
            'modul_tanimlari', 'uretim_modulleri', 'abonelik_planlari',
            'yetki_tanimlari'
        )
    LOOP
        -- RLS aktifleştir
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tablo_adi);

        -- Mevcut RLS politikalarını temizle (çakışma olmasın)
        policy_name := 'tenant_isolation_select_' || tablo_adi;
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, tablo_adi);

        policy_name := 'tenant_isolation_insert_' || tablo_adi;
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, tablo_adi);

        policy_name := 'tenant_isolation_update_' || tablo_adi;
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, tablo_adi);

        policy_name := 'tenant_isolation_delete_' || tablo_adi;
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_name, tablo_adi);

        -- SELECT: Kullanıcının aktif firmasına ait kayıtlar + firma_id NULL olanlar (legacy)
        EXECUTE format(
            'CREATE POLICY tenant_isolation_select_%I ON %I FOR SELECT USING (
                firma_id IS NULL
                OR firma_id = get_active_firma_id()
                OR is_platform_admin()
            )', tablo_adi, tablo_adi
        );

        -- INSERT: Sadece aktif firma için insert
        EXECUTE format(
            'CREATE POLICY tenant_isolation_insert_%I ON %I FOR INSERT WITH CHECK (
                firma_id = get_active_firma_id()
                OR is_platform_admin()
            )', tablo_adi, tablo_adi
        );

        -- UPDATE: Sadece kendi firmasının kayıtlarını güncelleyebilir
        EXECUTE format(
            'CREATE POLICY tenant_isolation_update_%I ON %I FOR UPDATE USING (
                firma_id = get_active_firma_id()
                OR is_platform_admin()
            )', tablo_adi, tablo_adi
        );

        -- DELETE: Sadece kendi firmasının kayıtlarını silebilir
        EXECUTE format(
            'CREATE POLICY tenant_isolation_delete_%I ON %I FOR DELETE USING (
                firma_id = get_active_firma_id()
                OR is_platform_admin()
            )', tablo_adi, tablo_adi
        );

        RAISE NOTICE 'RLS politikaları oluşturuldu: %', tablo_adi;
    END LOOP;
END $$;

DO $$ BEGIN RAISE NOTICE '✅ Aşama 1.3 tamamlandı: Tüm tablolar için RLS politikaları oluşturuldu.'; END $$;
