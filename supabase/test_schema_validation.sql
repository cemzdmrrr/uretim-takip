-- ================================================================================================
-- TEDARIKCI MODULU TEST VE DOGRULAMA SCRIPT'I
-- ================================================================================================
-- Bu script tedarikci modulu icin veritabani semasi dogrulamasini yapar
-- ================================================================================================

-- 1. Tedarikciler tablosunun mevcut durumunu kontrol et
\echo '=== TEDARİKÇİLER TABLOSU KOLON KONTROLÜ ==='
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'tedarikciler' 
ORDER BY ordinal_position;

-- 2. Primary key kontrolü
\echo '=== PRIMARY KEY KONTROLÜ ==='
SELECT 
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'tedarikciler' 
    AND tc.constraint_type = 'PRIMARY KEY';

-- 3. Check constraint'leri kontrol et
\echo '=== CHECK CONSTRAINT KONTROLÜ ==='
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.constraint_column_usage ccu 
    ON cc.constraint_name = ccu.constraint_name
WHERE ccu.table_name = 'tedarikciler';

-- 4. Test verisi ekleme denemesi
\echo '=== TEST VERİSİ EKLEME ==='
DO $$
BEGIN
    -- Test verisi ekle
    INSERT INTO tedarikciler (
        ad, sirket, telefon, cep_telefonu, email, web_sitesi,
        adres, il, ilce, posta_kodu, vergi_no, vergi_dairesi,
        tedarikci_tipi, faaliyet, durum, notlar,
        kredi_limiti, mevcut_borc, bakiye, odeme_vadesi, iskonto,
        iban_no, banka_adi, banka_subesi, banka_hesap_no, iban,
        hesap_sahibi, yetkili_kisi, yetkili_telefon, yetkili_email
    ) VALUES (
        'Test Tedarikçi',
        'Test Şirket A.Ş.',
        '0212 123 4567',
        '0532 123 4567',
        'test@example.com',
        'https://test.com',
        'Test Mahallesi Test Caddesi No:1',
        'İstanbul',
        'Kadıköy',
        '34000',
        '1234567890',
        'Test Vergi Dairesi',
        'Üretici',
        'Tekstil',
        'aktif',
        'Test amaçlı oluşturulan tedarikçi kaydı',
        50000.00,
        0.00,
        0.00,
        30,
        5.0,
        'TR33 0006 1005 1978 6457 8413 26',
        'Test Bankası',
        'Test Şubesi',
        '12345678',
        'TR33 0006 1005 1978 6457 8413 26',
        'Test Şirket A.Ş.',
        'Test Yetkili',
        '0532 987 6543',
        'yetkili@test.com'
    );
    
    RAISE NOTICE 'Test verisi başarıyla eklendi!';
    
    -- Eklenen veriyi sorgula
    PERFORM * FROM tedarikciler WHERE ad = 'Test Tedarikçi' LIMIT 1;
    RAISE NOTICE 'Test verisi sorgulandı!';
    
    -- Test verisini sil
    DELETE FROM tedarikciler WHERE ad = 'Test Tedarikçi';
    RAISE NOTICE 'Test verisi temizlendi!';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test sırasında hata oluştu: %', SQLERRM;
        ROLLBACK;
END $$;

-- 5. Eksik kolonları kontrol et
\echo '=== EKSİK KOLON KONTROLÜ ==='
DO $$
DECLARE
    missing_columns TEXT[];
    col TEXT;
    expected_columns TEXT[] := ARRAY[
        'id', 'ad', 'sirket', 'telefon', 'cep_telefonu', 'email', 'web_sitesi',
        'adres', 'il', 'ilce', 'posta_kodu', 'vergi_no', 'vergi_dairesi', 'tc_kimlik',
        'tedarikci_tipi', 'faaliyet', 'durum', 'notlar', 'kredi_limiti', 'mevcut_borc',
        'bakiye', 'odeme_vadesi', 'iskonto', 'iban_no', 'banka_adi', 'banka_subesi',
        'banka_hesap_no', 'iban', 'hesap_sahibi', 'yetkili_kisi', 'yetkili_telefon',
        'yetkili_email', 'kayit_tarihi', 'guncelleme_tarihi'
    ];
BEGIN
    missing_columns := ARRAY[]::TEXT[];
    
    FOREACH col IN ARRAY expected_columns LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'tedarikciler' AND column_name = col
        ) THEN
            missing_columns := missing_columns || col;
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE NOTICE 'EKSİK KOLONLAR: %', array_to_string(missing_columns, ', ');
    ELSE
        RAISE NOTICE 'TÜM GEREKLİ KOLONLAR MEVCUT! ✅';
    END IF;
END $$;

\echo '=== TEST TAMAMLANDI ==='
