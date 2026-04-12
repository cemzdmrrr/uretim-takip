-- ============================================================
-- FIRMA OLUŞTURMA RPC FONKSİYONU
-- RLS politikalarını bypass ederek firma oluşturma işlemini
-- tek bir atomik veritabanı çağrısında gerçekleştirir.
-- ============================================================

-- Önce mevcut fonksiyonu temizle
DROP FUNCTION IF EXISTS create_firma_with_owner(jsonb);

CREATE OR REPLACE FUNCTION create_firma_with_owner(p_data jsonb)
RETURNS jsonb AS $$
DECLARE
    v_user_id UUID;
    v_firma_id UUID;
    v_firma_adi TEXT;
    v_firma_kodu TEXT;
    v_deneme_plan_id UUID;
    v_modul RECORD;
    v_dal RECORD;
BEGIN
    -- Mevcut oturumdaki kullanıcıyı al
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Oturum açık değil';
    END IF;

    v_firma_adi := p_data->>'firma_adi';
    v_firma_kodu := p_data->>'firma_kodu';

    IF v_firma_adi IS NULL OR v_firma_kodu IS NULL THEN
        RAISE EXCEPTION 'firma_adi ve firma_kodu zorunlu';
    END IF;

    -- Firma kodu müsait mi?
    IF EXISTS (SELECT 1 FROM firmalar WHERE firma_kodu = v_firma_kodu) THEN
        RAISE EXCEPTION 'Bu firma kodu zaten kullanımda: %', v_firma_kodu;
    END IF;

    -- 1. Firma oluştur
    INSERT INTO firmalar (firma_adi, firma_kodu, vergi_no, vergi_dairesi, telefon, email, adres)
    VALUES (
        v_firma_adi,
        v_firma_kodu,
        p_data->>'vergi_no',
        p_data->>'vergi_dairesi',
        p_data->>'telefon',
        p_data->>'email',
        p_data->>'adres'
    )
    RETURNING id INTO v_firma_id;

    -- 2. Kullanıcıyı firma sahibi yap
    INSERT INTO firma_kullanicilari (firma_id, user_id, rol, aktif, katilim_tarihi)
    VALUES (v_firma_id, v_user_id, 'firma_sahibi', true, NOW());

    -- 3. Aktif firma olarak ayarla
    INSERT INTO kullanici_aktif_firma (user_id, firma_id)
    VALUES (v_user_id, v_firma_id)
    ON CONFLICT (user_id) DO UPDATE SET firma_id = v_firma_id;

    -- 4. Tüm modülleri ata (deneme döneminde tüm modüller dahil)
    FOR v_modul IN SELECT id FROM modul_tanimlari WHERE aktif = true
    LOOP
        INSERT INTO firma_modulleri (firma_id, modul_id, aktif)
        VALUES (v_firma_id, v_modul.id, true)
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- 5. Üretim dallarını ata
    IF p_data ? 'secilen_uretim_dallari' AND jsonb_array_length(p_data->'secilen_uretim_dallari') > 0 THEN
        FOR v_dal IN
            SELECT id FROM uretim_modulleri
            WHERE modul_kodu = ANY(
                SELECT jsonb_array_elements_text(p_data->'secilen_uretim_dallari')
            )
        LOOP
            INSERT INTO firma_uretim_modulleri (firma_id, uretim_modul_id, aktif)
            VALUES (v_firma_id, v_dal.id, true)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END IF;

    -- 6. Deneme aboneliği başlat
    SELECT id INTO v_deneme_plan_id FROM abonelik_planlari WHERE plan_kodu = 'deneme' LIMIT 1;
    IF v_deneme_plan_id IS NOT NULL THEN
        INSERT INTO firma_abonelikleri (firma_id, plan_id, durum, odeme_periyodu)
        VALUES (v_firma_id, v_deneme_plan_id, 'deneme', 'aylik');
    END IF;

    RETURN jsonb_build_object('firma_id', v_firma_id, 'success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Authenticated kullanıcıların çağırabilmesi için yetki ver
GRANT EXECUTE ON FUNCTION create_firma_with_owner(jsonb) TO authenticated;

DO $$ BEGIN RAISE NOTICE 'create_firma_with_owner RPC fonksiyonu oluşturuldu.'; END $$;
