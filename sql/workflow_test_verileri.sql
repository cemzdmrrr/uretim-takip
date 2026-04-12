-- Yeni İş Akışı Sistemi Test Verileri
-- Bu dosya geliştirilen workflow sistemini test etmek için örnek veriler içerir

-- 1. Test kullanıcıları oluştur (farklı rollerde)
DO $$
DECLARE
    admin_user_id UUID := gen_random_uuid();
    dokuma_user_id UUID := gen_random_uuid();
    kalite_user_id UUID := gen_random_uuid();
    sevkiyat_user_id UUID := gen_random_uuid();
BEGIN
    -- Test kullanıcıları ve rolleri
    INSERT INTO user_roles (user_id, role, aktif) VALUES
    (admin_user_id, 'admin', true),
    (dokuma_user_id, 'dokuma_firmasi', true),
    (kalite_user_id, 'kalite_guvence', true),
    (sevkiyat_user_id, 'sevkiyat_personeli', true)
    ON CONFLICT (user_id) DO UPDATE SET
        role = EXCLUDED.role,
        aktif = EXCLUDED.aktif;

    -- Test atölyesi oluştur
    INSERT INTO atolyeler (id, atolye_adi, atolye_turu, aktif) VALUES
    (100, 'Test Dokuma Firması', 'Dokuma', true),
    (101, 'Test Konfeksiyon Firması', 'Konfeksiyon', true),
    (102, 'Test Kalite Departmanı', 'Kalite', true),
    (103, 'Test Sevkiyat Departmanı', 'Sevkiyat', true)
    ON CONFLICT (id) DO UPDATE SET
        atolye_adi = EXCLUDED.atolye_adi,
        atolye_turu = EXCLUDED.atolye_turu,
        aktif = EXCLUDED.aktif;

    -- Test model verisi
    INSERT INTO triko_takip (id, marka, item_no, adet, renk, urun_cinsi) VALUES
    (gen_random_uuid(), 'TEST MARKA', 'TEST001', 100, 'Kırmızı', 'T-Shirt')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Test verileri oluşturuldu';
    RAISE NOTICE 'Admin User ID: %', admin_user_id;
    RAISE NOTICE 'Dokuma User ID: %', dokuma_user_id;
    RAISE NOTICE 'Kalite User ID: %', kalite_user_id;
    RAISE NOTICE 'Sevkiyat User ID: %', sevkiyat_user_id;
END $$;

-- 2. Test workflow senaryosu
-- Bu senaryo tam iş akışını simüle eder:
-- Admin atama → Firma onayı → Üretim başlatma → Üretim tamamlama → Kalite kontrol → Sevkiyat

DO $$
DECLARE
    test_model_id UUID;
    test_admin_id UUID;
    test_dokuma_id UUID;
    test_atama_id UUID;
BEGIN
    -- Test model ID'sini al
    SELECT id INTO test_model_id FROM triko_takip WHERE item_no = 'TEST001' LIMIT 1;
    
    -- Test admin ID'sini al
    SELECT user_id INTO test_admin_id FROM user_roles WHERE role = 'admin' LIMIT 1;
    
    -- Test dokuma firma ID'sini al
    SELECT user_id INTO test_dokuma_id FROM user_roles WHERE role = 'dokuma_firmasi' LIMIT 1;

    IF test_model_id IS NOT NULL AND test_admin_id IS NOT NULL THEN
        -- ADIM 1: Admin tarafından dokuma firmasına atama
        INSERT INTO uretim_kayitlari (
            id,
            model_id,
            asama,
            firma_id,
            tamamlanan_adet,
            uretici_user_id,
            durum,
            atama_durumu,
            atama_yapan_user_id,
            uretilen_adet,
            notlar
        ) VALUES (
            gen_random_uuid(),
            test_model_id,
            'orgu',
            100, -- Test Dokuma Firması ID
            50, -- 50 adet
            test_admin_id,
            'firma_onay_bekliyor',
            'firma_onay_bekliyor',
            test_admin_id,
            0,
            'Test admin ataması'
        )
        RETURNING id INTO test_atama_id;

        -- ADIM 2: Dokuma firmasına bildirim gönder
        IF test_dokuma_id IS NOT NULL THEN
            INSERT INTO bildirimler (
                user_id,
                baslik,
                mesaj,
                tip,
                model_id,
                atama_id,
                asama,
                okundu
            ) VALUES (
                test_dokuma_id,
                'Yeni İş Ataması - orgu',
                'Test Dokuma Firması firmasına 50 adet ürün için orgu aşaması ataması yapıldı. Onay vermeniz bekleniyor.',
                'atama_bekliyor',
                test_model_id,
                test_atama_id,
                'orgu',
                false
            );
        END IF;

        RAISE NOTICE 'Test workflow başlatıldı!';
        RAISE NOTICE 'Atama ID: %', test_atama_id;
        RAISE NOTICE 'Model ID: %', test_model_id;
        RAISE NOTICE 'Dokuma firması giriş yapıp atamayı onaylayabilir.';
    ELSE
        RAISE NOTICE 'Test verileri bulunamadı!';
    END IF;
END $$;

-- 3. Workflow durum kontrol sorgusu
SELECT 
    'ATAMA DURUMU' as tablo_adi,
    uk.id,
    uk.asama,
    a.atolye_adi as firma,
    uk.tamamlanan_adet as hedef_adet,
    uk.uretilen_adet,
    uk.durum,
    uk.atama_durumu,
    uk.created_at as atama_tarihi
FROM uretim_kayitlari uk
LEFT JOIN atolyeler a ON uk.firma_id = a.id
ORDER BY uk.created_at DESC
LIMIT 5;

-- 4. Bildirim durumu
SELECT 
    'BİLDİRİM DURUMU' as tablo_adi,
    b.baslik,
    b.tip,
    ur.role as alici_rol,
    b.okundu,
    b.created_at
FROM bildirimler b
LEFT JOIN user_roles ur ON b.user_id = ur.user_id
ORDER BY b.created_at DESC
LIMIT 5;

-- 5. Kullanım kılavuzu
SELECT 'KULLANIM KILAVUZU' as baslik, 
       'Workflow Test Adımları:
       
1. Admin kullanıcı olarak giriş yapın
2. Model detay sayfasına gidin (TEST MARKA - TEST001)
3. Örgü aşamasında Test Dokuma Firmasını seçin
4. 50 adet girin ve "Atama Yap" butonuna basın
5. Dokuma firma kullanıcısı olarak giriş yapın
6. Bildirimler sayfasını kontrol edin
7. "Kabul Et" butonuna basın
8. "Üretime Başla" butonuna basın
9. Tarihleri girin ve üretime başlayın
10. "Üretimi Tamamla" butonuna basın
11. Üretilen adet girin (örn: 48)
12. Kalite güvence kullanıcısı olarak giriş yapın
13. Kalite kontrolü yapın ve onaylayın
14. Sevkiyat personeli olarak giriş yapın
15. Sevkiyatı tamamlayın ve sonraki aşamaya gönderin

Test tamamlandığında tam workflow çalışmış olacak!' as aciklama;