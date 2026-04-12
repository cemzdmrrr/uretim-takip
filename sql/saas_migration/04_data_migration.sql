-- ============================================================
-- AŞAMA 1.4: MEVCUT VERİ MİGRASYONU
-- TexPilot SaaS Dönüşümü - Mevcut Verilerin Firma'ya Atanması
-- ============================================================
-- Bu script mevcut verileri varsayılan firmaya atar.
-- Mevcut kullanıcıları firma_kullanicilari tablosuna ekler.
-- Triko üretim modülünü varsayılan firma için aktif eder.
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- 1. VARSAYILAN FİRMA OLUŞTUR
-- ─────────────────────────────────────────────────────────

-- Önce sirket_bilgileri tablosundan mevcut firma bilgilerini al
DO $$
DECLARE
    v_firma_id UUID;
    v_firma_adi TEXT;
    v_vergi_no TEXT;
    v_vergi_dairesi TEXT;
    v_adres TEXT;
    v_telefon TEXT;
    v_email TEXT;
    t TEXT;
BEGIN
    -- Mevcut şirket bilgilerini oku (kolon adları kuruluma göre değişebilir)
    BEGIN
        SELECT
            COALESCE(sirket_adi, 'Varsayılan Firma'),
            vergi_no, vergi_dairesi, adres, telefon, email
        INTO
            v_firma_adi, v_vergi_no, v_vergi_dairesi, v_adres, v_telefon, v_email
        FROM sirket_bilgileri
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'sirket_bilgileri okunamadı: %, varsayılan değerler kullanılacak.', SQLERRM;
    END;

    -- Eğer sirket_bilgileri boşsa veya okunamadıysa varsayılan değerler kullan
    IF v_firma_adi IS NULL THEN
        v_firma_adi := 'Varsayılan Firma';
    END IF;

    -- Firma zaten oluşturulmuş mu kontrol et
    SELECT id INTO v_firma_id FROM firmalar WHERE firma_kodu = 'varsayilan-firma' LIMIT 1;

    IF v_firma_id IS NULL THEN
        INSERT INTO firmalar (
            firma_adi, firma_kodu, vergi_no, vergi_dairesi, adres,
            telefon, email, sektor
        ) VALUES (
            v_firma_adi, 'varsayilan-firma', v_vergi_no, v_vergi_dairesi, v_adres,
            v_telefon, v_email, 'tekstil'
        ) RETURNING id INTO v_firma_id;

        RAISE NOTICE 'Varsayılan firma oluşturuldu: % (ID: %)', v_firma_adi, v_firma_id;
    ELSE
        RAISE NOTICE 'Varsayılan firma zaten mevcut: %', v_firma_id;
    END IF;

    -- ─────────────────────────────────────────────────────
    -- 2. MEVCUT KULLANICILARI FİRMAYA ATA
    -- ─────────────────────────────────────────────────────

    -- user_roles tablosundan mevcut kullanıcıları al ve firma_kullanicilari'na ekle
    INSERT INTO firma_kullanicilari (firma_id, user_id, rol, aktif, katilim_tarihi)
    SELECT
        v_firma_id,
        ur.user_id,
        CASE
            WHEN ur.role = 'admin' THEN 'firma_sahibi'
            WHEN ur.role = 'yonetici' THEN 'yonetici'
            WHEN ur.role = 'kullanici' THEN 'kullanici'
            WHEN ur.role = 'personel' THEN 'personel'
            WHEN ur.role = 'dokuma' THEN 'dokumaci'
            WHEN ur.role = 'konfeksiyon' THEN 'konfeksiyoncu'
            WHEN ur.role = 'kalite_kontrol' THEN 'kalite_kontrol'
            WHEN ur.role = 'sofor' THEN 'sofor'
            WHEN ur.role = 'sevkiyat' THEN 'kullanici'
            WHEN ur.role = 'utu' THEN 'kullanici'
            WHEN ur.role = 'utu_paket' THEN 'kullanici'
            WHEN ur.role = 'paketleme' THEN 'kullanici'
            WHEN ur.role = 'ilik_dugme' THEN 'kullanici'
            WHEN ur.role = 'nakis' THEN 'kullanici'
            WHEN ur.role = 'yikama' THEN 'kullanici'
            WHEN ur.role = 'depo' THEN 'depocu'
            ELSE 'kullanici'
        END,
        COALESCE(ur.aktif, true),
        NOW()
    FROM user_roles ur
    WHERE NOT EXISTS (
        SELECT 1 FROM firma_kullanicilari fk
        WHERE fk.firma_id = v_firma_id AND fk.user_id = ur.user_id
    )
    ON CONFLICT (firma_id, user_id) DO NOTHING;

    RAISE NOTICE 'Mevcut kullanıcılar firmaya atandı.';

    -- ─────────────────────────────────────────────────────
    -- 3. AKTİF FİRMA KAYDI OLUŞTUR
    -- ─────────────────────────────────────────────────────

    INSERT INTO kullanici_aktif_firma (user_id, firma_id)
    SELECT user_id, v_firma_id FROM firma_kullanicilari
    WHERE firma_id = v_firma_id
    ON CONFLICT (user_id) DO NOTHING;

    RAISE NOTICE 'Kullanıcı aktif firma kayıtları oluşturuldu.';

    -- ─────────────────────────────────────────────────────
    -- 4. MEVCUT VERİLERE firma_id ATA
    -- Mevcut olmayan tablolar otomatik olarak atlanır
    -- ─────────────────────────────────────────────────────

    FOREACH t IN ARRAY ARRAY[
        'triko_takip', 'modeller', 'uretim_kayitlari', 'model_kritikleri',
        'beden_tanimlari', 'model_beden_dagilimi', 'dokuma_beden_takip',
        'dokuma_atamalari', 'konfeksiyon_atamalari', 'kalite_kontrol_atamalari',
        'paketleme_atamalari', 'utu_atamalari', 'yikama_atamalari',
        'nakis_atamalari', 'ilik_dugme_atamalari',
        'iplik_stoklari', 'iplik_hareketleri', 'iplik_siparisleri',
        'iplik_stok_hareketleri', 'stok_hareketleri',
        'aksesuarlar', 'aksesuar_stok', 'aksesuar_kullanim',
        'aksesuar_bedenler', 'model_aksesuar',
        'faturalar', 'fatura_kalemleri', 'kasa_banka_hesaplari',
        'kasa_banka_hareketleri', 'odeme_kayitlari', 'odeme_gecmisi',
        'maliyet_hesaplama', 'donemler',
        'tedarikciler', 'tedarikci_siparisleri', 'tedarikci_odemeleri',
        'musteriler',
        'sevkiyat_kayitlari', 'sevkiyat_detaylari', 'sevk_talepleri',
        'ceki_listesi', 'yukleme_kayitlari',
        'personel', 'personel_donem', 'bordro',
        'mesai', 'mesai_kayitlari', 'puantaj', 'izinler', 'izin_kayitlari',
        'atolyeler', 'bildirimler', 'dosyalar', 'teknik_dosyalar', 'urun_depo'
    ] LOOP
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema='public' AND table_name=t AND column_name='firma_id' AND udt_name='uuid') THEN
            EXECUTE format('UPDATE %I SET firma_id = $1 WHERE firma_id IS NULL', t) USING v_firma_id;
            RAISE NOTICE 'firma_id atandı: %', t;
        ELSE
            RAISE NOTICE 'Tablo/kolon mevcut değil, atlanıyor: %', t;
        END IF;
    END LOOP;

    RAISE NOTICE 'Tüm mevcut veriler varsayılan firmaya atandı.';

    -- ─────────────────────────────────────────────────────
    -- 5. VARSAYILAN FİRMA İÇİN MODÜL AKTİVASYONU
    -- ─────────────────────────────────────────────────────

    -- Tüm modülleri varsayılan firma için aktif et
    INSERT INTO firma_modulleri (firma_id, modul_id, aktif)
    SELECT v_firma_id, id, true FROM modul_tanimlari
    ON CONFLICT (firma_id, modul_id) DO NOTHING;

    -- Triko üretim dalını varsayılan firma için aktif et
    INSERT INTO firma_uretim_modulleri (firma_id, uretim_modul_id, aktif)
    SELECT v_firma_id, id, true FROM uretim_modulleri WHERE modul_kodu = 'triko'
    ON CONFLICT (firma_id, uretim_modul_id) DO NOTHING;

    RAISE NOTICE 'Varsayılan firma modülleri aktifleştirildi.';

    -- ─────────────────────────────────────────────────────
    -- 6. VARSAYILAN FİRMA İÇİN DENEME ABONELİĞİ
    -- ─────────────────────────────────────────────────────

    -- Kurumsal plan ile başlatsın (mevcut firma zaten full erişime sahipti)
    INSERT INTO firma_abonelikleri (firma_id, plan_id, durum, baslangic_tarihi, deneme_bitis)
    SELECT v_firma_id, id, 'aktif', NOW(), NULL
    FROM abonelik_planlari WHERE plan_kodu = 'kurumsal'
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Varsayılan firma aboneliği oluşturuldu (Kurumsal plan).';

END $$;

DO $$ BEGIN RAISE NOTICE '✅ Aşama 1.4 tamamlandı: Mevcut veriler varsayılan firmaya migrate edildi.'; END $$;
