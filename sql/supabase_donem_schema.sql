-- ================================================================================================
-- DÖNEM YÖNETİMİ VERİTABANI ŞEMASI
-- ================================================================================================
-- Bu script, mevcut Supabase veritabanınıza dönem yönetimi özelliği ekler.
-- 
-- YAPILAN İŞLEMLER:
-- 1. 'donemler' tablosunu oluşturur (kod, ad, başlangıç/bitiş tarihleri, aktif durumu)
-- 2. Mevcut tablolara 'donem' sütunu ekler (bordro, izinler, mesai, odemeler)
-- 3. Sütun tiplerini kontrol eder ve gerekirse DATE'den VARCHAR'a çevirir
-- 4. Foreign key kısıtlamalarını ekler
-- 5. Tek aktif dönem sağlayan trigger'ları oluşturur
-- 6. RLS politikalarını ayarlar
-- 7. Mevcut kayıtları aktif döneme atar
-- 
-- ÖNEMLI NOTLAR:
-- - Bu script idempotent'tır (tekrar çalıştırılabilir)
-- - Mevcut verileri korur
-- - Tip uyumsuzluklarını otomatik olarak düzeltir
-- - Hata durumlarında detaylı log mesajları verir
-- ================================================================================================

-- Dönemler tablosu (eğer yoksa oluştur)
CREATE TABLE IF NOT EXISTS donemler (
    id SERIAL PRIMARY KEY,
    kod VARCHAR(50) UNIQUE NOT NULL,
    ad VARCHAR(100) NOT NULL,
    baslangic_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    aktif BOOLEAN DEFAULT FALSE,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Guncelleme_tarihi otomatik güncellemesi için trigger
CREATE OR REPLACE FUNCTION update_guncelleme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS donemler_guncelleme_tarihi_trigger ON donemler;
CREATE TRIGGER donemler_guncelleme_tarihi_trigger
    BEFORE UPDATE ON donemler
    FOR EACH ROW
    EXECUTE FUNCTION update_guncelleme_tarihi();

-- Tek aktif dönem kontrolü için trigger
CREATE OR REPLACE FUNCTION tek_aktif_donem_kontrolu()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer yeni kayıt aktif olarak ayarlanıyorsa, diğerlerini pasif yap
    IF NEW.aktif = TRUE THEN
        UPDATE donemler SET aktif = FALSE WHERE id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tek_aktif_donem_trigger ON donemler;
CREATE TRIGGER tek_aktif_donem_trigger
    BEFORE INSERT OR UPDATE ON donemler
    FOR EACH ROW
    EXECUTE FUNCTION tek_aktif_donem_kontrolu();

-- Bordro tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='bordro' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE bordro ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'bordro.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'bordro.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE bordro ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE bordro SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE bordro DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE bordro RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'bordro.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'bordro.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'bordro.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- İzinler tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='izinler' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE izinler ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'izinler.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'izinler.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE izinler ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE izinler SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE izinler DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE izinler RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'izinler.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'izinler.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'izinler.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- Mesai tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='mesai' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE mesai ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'mesai.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'mesai.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE mesai ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE mesai SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE mesai DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE mesai RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'mesai.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'mesai.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'mesai.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- Ödeme tablosuna dönem ekle (eğer tablo varsa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
    table_exists BOOLEAN;
BEGIN 
    -- Tablo var mı kontrol et
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'odemeler'
    ) INTO table_exists;
    
    IF table_exists THEN
        -- Sütun var mı kontrol et
        SELECT data_type INTO col_type 
        FROM information_schema.columns 
        WHERE table_name='odemeler' AND column_name='donem';
        
        IF col_type IS NULL THEN
            -- Sütun yoksa VARCHAR olarak ekle
            ALTER TABLE odemeler ADD COLUMN donem VARCHAR(50);
            RAISE NOTICE 'odemeler.donem sütunu VARCHAR(50) olarak eklendi';
        ELSIF col_type = 'date' THEN
            -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
            RAISE NOTICE 'odemeler.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
            
            -- Yeni sütun ekle
            ALTER TABLE odemeler ADD COLUMN donem_temp VARCHAR(50);
            
            -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
            UPDATE odemeler SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
            
            -- Eski sütunu sil
            ALTER TABLE odemeler DROP COLUMN donem;
            
            -- Yeni sütunu donem olarak yeniden adlandır
            ALTER TABLE odemeler RENAME COLUMN donem_temp TO donem;
            
            RAISE NOTICE 'odemeler.donem sütunu VARCHAR(50) tipine çevrildi';
        ELSIF col_type != 'character varying' THEN
            RAISE EXCEPTION 'odemeler.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
        ELSE
            RAISE NOTICE 'odemeler.donem sütunu zaten VARCHAR tipinde';
        END IF;
    ELSE
        RAISE NOTICE 'odemeler tablosu bulunamadı, atlanıyor';
    END IF;
END $$;

-- Bordro tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='bordro' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE bordro ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'bordro.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'bordro.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE bordro ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE bordro SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE bordro DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE bordro RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'bordro.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'bordro.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'bordro.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- ÖNCE EKSİK DÖNEMLERİ OLUŞTUR (TÜM SÜTUNLAR VARCHAR OLDUĞUNA GÖRE)
DO $$
DECLARE
    donem_kod VARCHAR(50);
    yil INT;
    ay INT;
    ay_adi VARCHAR(20);
    baslangic DATE;
    bitis DATE;
BEGIN
    -- Bordro tablosundaki eksik dönemleri oluştur
    FOR donem_kod IN 
        SELECT DISTINCT donem FROM bordro 
        WHERE donem IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM donemler WHERE kod = bordro.donem)
    LOOP
        BEGIN
            yil := CAST(SPLIT_PART(donem_kod, '-', 1) AS INT);
            ay := CAST(SPLIT_PART(donem_kod, '-', 2) AS INT);
            
            ay_adi := CASE ay
                WHEN 1 THEN 'Ocak' WHEN 2 THEN 'Şubat' WHEN 3 THEN 'Mart'
                WHEN 4 THEN 'Nisan' WHEN 5 THEN 'Mayıs' WHEN 6 THEN 'Haziran'
                WHEN 7 THEN 'Temmuz' WHEN 8 THEN 'Ağustos' WHEN 9 THEN 'Eylül'
                WHEN 10 THEN 'Ekim' WHEN 11 THEN 'Kasım' WHEN 12 THEN 'Aralık'
                ELSE 'Bilinmeyen'
            END;
            
            baslangic := MAKE_DATE(yil, ay, 1);
            bitis := (MAKE_DATE(yil, ay, 1) + INTERVAL '1 month - 1 day')::DATE;
            
            INSERT INTO donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif)
            VALUES (donem_kod, ay_adi || ' ' || yil, baslangic, bitis, FALSE);
            
            RAISE NOTICE 'Dönem oluşturuldu: % - %', donem_kod, ay_adi || ' ' || yil;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Geçersiz dönem formatı: %', donem_kod;
        END;
    END LOOP;
    
    -- İzinler tablosundaki eksik dönemleri oluştur
    FOR donem_kod IN 
        SELECT DISTINCT donem FROM izinler 
        WHERE donem IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM donemler WHERE kod = izinler.donem)
    LOOP
        BEGIN
            yil := CAST(SPLIT_PART(donem_kod, '-', 1) AS INT);
            ay := CAST(SPLIT_PART(donem_kod, '-', 2) AS INT);
            
            ay_adi := CASE ay
                WHEN 1 THEN 'Ocak' WHEN 2 THEN 'Şubat' WHEN 3 THEN 'Mart'
                WHEN 4 THEN 'Nisan' WHEN 5 THEN 'Mayıs' WHEN 6 THEN 'Haziran'
                WHEN 7 THEN 'Temmuz' WHEN 8 THEN 'Ağustos' WHEN 9 THEN 'Eylül'
                WHEN 10 THEN 'Ekim' WHEN 11 THEN 'Kasım' WHEN 12 THEN 'Aralık'
                ELSE 'Bilinmeyen'
            END;
            
            baslangic := MAKE_DATE(yil, ay, 1);
            bitis := (MAKE_DATE(yil, ay, 1) + INTERVAL '1 month - 1 day')::DATE;
            
            INSERT INTO donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif)
            VALUES (donem_kod, ay_adi || ' ' || yil, baslangic, bitis, FALSE);
            
            RAISE NOTICE 'Dönem oluşturuldu: % - %', donem_kod, ay_adi || ' ' || yil;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Geçersiz dönem formatı: %', donem_kod;
        END;
    END LOOP;
    
    -- Mesai tablosundaki eksik dönemleri oluştur
    FOR donem_kod IN 
        SELECT DISTINCT donem FROM mesai 
        WHERE donem IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM donemler WHERE kod = mesai.donem)
    LOOP
        BEGIN
            yil := CAST(SPLIT_PART(donem_kod, '-', 1) AS INT);
            ay := CAST(SPLIT_PART(donem_kod, '-', 2) AS INT);
            
            ay_adi := CASE ay
                WHEN 1 THEN 'Ocak' WHEN 2 THEN 'Şubat' WHEN 3 THEN 'Mart'
                WHEN 4 THEN 'Nisan' WHEN 5 THEN 'Mayıs' WHEN 6 THEN 'Haziran'
                WHEN 7 THEN 'Temmuz' WHEN 8 THEN 'Ağustos' WHEN 9 THEN 'Eylül'
                WHEN 10 THEN 'Ekim' WHEN 11 THEN 'Kasım' WHEN 12 THEN 'Aralık'
                ELSE 'Bilinmeyen'
            END;
            
            baslangic := MAKE_DATE(yil, ay, 1);
            bitis := (MAKE_DATE(yil, ay, 1) + INTERVAL '1 month - 1 day')::DATE;
            
            INSERT INTO donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif)
            VALUES (donem_kod, ay_adi || ' ' || yil, baslangic, bitis, FALSE);
            
            RAISE NOTICE 'Dönem oluşturuldu: % - %', donem_kod, ay_adi || ' ' || yil;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Geçersiz dönem formatı: %', donem_kod;
        END;
    END LOOP;
    
    -- Ödemeler tablosundaki eksik dönemleri oluştur (eğer tablo varsa)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='odemeler') THEN
        FOR donem_kod IN 
            SELECT DISTINCT donem FROM odemeler 
            WHERE donem IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM donemler WHERE kod = odemeler.donem)
        LOOP
            BEGIN
                yil := CAST(SPLIT_PART(donem_kod, '-', 1) AS INT);
                ay := CAST(SPLIT_PART(donem_kod, '-', 2) AS INT);
                
                ay_adi := CASE ay
                    WHEN 1 THEN 'Ocak' WHEN 2 THEN 'Şubat' WHEN 3 THEN 'Mart'
                    WHEN 4 THEN 'Nisan' WHEN 5 THEN 'Mayıs' WHEN 6 THEN 'Haziran'
                    WHEN 7 THEN 'Temmuz' WHEN 8 THEN 'Ağustos' WHEN 9 THEN 'Eylül'
                    WHEN 10 THEN 'Ekim' WHEN 11 THEN 'Kasım' WHEN 12 THEN 'Aralık'
                    ELSE 'Bilinmeyen'
                END;
                
                baslangic := MAKE_DATE(yil, ay, 1);
                bitis := (MAKE_DATE(yil, ay, 1) + INTERVAL '1 month - 1 day')::DATE;
                
                INSERT INTO donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif)
                VALUES (donem_kod, ay_adi || ' ' || yil, baslangic, bitis, FALSE);
                
                RAISE NOTICE 'Dönem oluşturuldu: % - %', donem_kod, ay_adi || ' ' || yil;
                
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Geçersiz dönem formatı: %', donem_kod;
            END;
        END LOOP;
    END IF;
    
    -- Hiç dönem yoksa varsayılan dönem ekle
    IF NOT EXISTS (SELECT 1 FROM donemler LIMIT 1) THEN
        INSERT INTO donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif)
        VALUES ('2025-06', 'Haziran 2025', '2025-06-01', '2025-06-30', TRUE);
        RAISE NOTICE 'Varsayılan dönem eklendi: 2025-06';
    END IF;
    
    -- Aktif dönem yoksa en son dönemi aktif yap
    IF NOT EXISTS (SELECT 1 FROM donemler WHERE aktif = TRUE) THEN
        UPDATE donemler SET aktif = TRUE 
        WHERE kod = (SELECT kod FROM donemler ORDER BY baslangic_tarihi DESC LIMIT 1);
        RAISE NOTICE 'En son dönem aktif yapıldı';
    END IF;
    
END $$;

-- Bordro donem foreign key constraint ekle
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='bordro_donem_fkey') THEN
        ALTER TABLE bordro ADD CONSTRAINT bordro_donem_fkey 
        FOREIGN KEY (donem) REFERENCES donemler(kod);
        RAISE NOTICE 'bordro_donem_fkey constraint eklendi';
    END IF;
END $$;

-- İzinler tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='izinler' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE izinler ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'izinler.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'izinler.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE izinler ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE izinler SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE izinler DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE izinler RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'izinler.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'izinler.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'izinler.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- İzinler donem foreign key constraint ekle
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='izinler_donem_fkey') THEN
        ALTER TABLE izinler ADD CONSTRAINT izinler_donem_fkey 
        FOREIGN KEY (donem) REFERENCES donemler(kod);
        RAISE NOTICE 'izinler_donem_fkey constraint eklendi';
    END IF;
END $$;

-- Mesai tablosuna dönem ekle (eğer yoksa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
BEGIN 
    -- Sütun var mı kontrol et
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name='mesai' AND column_name='donem';
    
    IF col_type IS NULL THEN
        -- Sütun yoksa VARCHAR olarak ekle
        ALTER TABLE mesai ADD COLUMN donem VARCHAR(50);
        RAISE NOTICE 'mesai.donem sütunu VARCHAR(50) olarak eklendi';
    ELSIF col_type = 'date' THEN
        -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
        RAISE NOTICE 'mesai.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
        
        -- Yeni sütun ekle
        ALTER TABLE mesai ADD COLUMN donem_temp VARCHAR(50);
        
        -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
        UPDATE mesai SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
        
        -- Eski sütunu sil
        ALTER TABLE mesai DROP COLUMN donem;
        
        -- Yeni sütunu donem olarak yeniden adlandır
        ALTER TABLE mesai RENAME COLUMN donem_temp TO donem;
        
        RAISE NOTICE 'mesai.donem sütunu VARCHAR(50) tipine çevrildi';
    ELSIF col_type != 'character varying' THEN
        RAISE EXCEPTION 'mesai.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
    ELSE
        RAISE NOTICE 'mesai.donem sütunu zaten VARCHAR tipinde';
    END IF;
END $$;

-- Mesai donem foreign key constraint ekle
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='mesai_donem_fkey') THEN
        ALTER TABLE mesai ADD CONSTRAINT mesai_donem_fkey 
        FOREIGN KEY (donem) REFERENCES donemler(kod);
        RAISE NOTICE 'mesai_donem_fkey constraint eklendi';
    END IF;
END $$;

-- Ödeme tablosuna dönem ekle (eğer tablo varsa) ve tip uyumluluğunu kontrol et
DO $$ 
DECLARE
    col_type TEXT;
    table_exists BOOLEAN;
BEGIN 
    -- Tablo var mı kontrol et
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'odemeler'
    ) INTO table_exists;
    
    IF table_exists THEN
        -- Sütun var mı kontrol et
        SELECT data_type INTO col_type 
        FROM information_schema.columns 
        WHERE table_name='odemeler' AND column_name='donem';
        
        IF col_type IS NULL THEN
            -- Sütun yoksa VARCHAR olarak ekle
            ALTER TABLE odemeler ADD COLUMN donem VARCHAR(50);
            RAISE NOTICE 'odemeler.donem sütunu VARCHAR(50) olarak eklendi';
        ELSIF col_type = 'date' THEN
            -- Eğer DATE tipindeyse, önce VARCHAR'a çevir
            RAISE NOTICE 'odemeler.donem sütunu DATE tipinde, VARCHAR''a çevriliyor...';
            
            -- Yeni sütun ekle
            ALTER TABLE odemeler ADD COLUMN donem_temp VARCHAR(50);
            
            -- Mevcut DATE değerlerini VARCHAR'a çevir (YYYY-MM formatında)
            UPDATE odemeler SET donem_temp = TO_CHAR(donem, 'YYYY-MM') WHERE donem IS NOT NULL;
            
            -- Eski sütunu sil
            ALTER TABLE odemeler DROP COLUMN donem;
            
            -- Yeni sütunu donem olarak yeniden adlandır
            ALTER TABLE odemeler RENAME COLUMN donem_temp TO donem;
            
            RAISE NOTICE 'odemeler.donem sütunu VARCHAR(50) tipine çevrildi';
        ELSIF col_type != 'character varying' THEN
            RAISE EXCEPTION 'odemeler.donem sütunu beklenmeyen tipte: %. Lütfen manuel olarak VARCHAR(50) tipine çevirin.', col_type;
        ELSE
            RAISE NOTICE 'odemeler.donem sütunu zaten VARCHAR tipinde';
        END IF;
        
        -- Foreign key constraint ekle
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name='odemeler_donem_fkey') THEN
            ALTER TABLE odemeler ADD CONSTRAINT odemeler_donem_fkey 
            FOREIGN KEY (donem) REFERENCES donemler(kod);
            RAISE NOTICE 'odemeler_donem_fkey constraint eklendi';
        END IF;
    ELSE
        RAISE NOTICE 'odemeler tablosu bulunamadı, atlanıyor';
    END IF;
END $$;

-- RLS (Row Level Security) politikaları
ALTER TABLE donemler ENABLE ROW LEVEL SECURITY;

-- Donemler tablosu için politikalar
DROP POLICY IF EXISTS "Donemler görüntüleme" ON donemler;
CREATE POLICY "Donemler görüntüleme" ON donemler
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Donemler ekleme" ON donemler;
CREATE POLICY "Donemler ekleme" ON donemler
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Donemler güncelleme" ON donemler;
CREATE POLICY "Donemler güncelleme" ON donemler
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Donemler silme" ON donemler;
CREATE POLICY "Donemeler silme" ON donemler
    FOR DELETE USING (true);

-- Mevcut kayıtları aktif döneme ata
DO $$
DECLARE
    aktif_donem_kod VARCHAR(50);
BEGIN
    -- Aktif dönem kodunu al
    SELECT kod INTO aktif_donem_kod 
    FROM donemler 
    WHERE aktif = TRUE 
    LIMIT 1;
    
    IF aktif_donem_kod IS NOT NULL THEN
        RAISE NOTICE 'Aktif dönem bulundu: %', aktif_donem_kod;
        
        -- Bordro kayıtlarını güncelle
        UPDATE bordro SET donem = aktif_donem_kod WHERE donem IS NULL;
        
        -- İzin kayıtlarını güncelle
        UPDATE izinler SET donem = aktif_donem_kod WHERE donem IS NULL;
        
        -- Mesai kayıtlarını güncelle
        UPDATE mesai SET donem = aktif_donem_kod WHERE donem IS NULL;
        
        -- Eğer odemeler tablosu varsa
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='odemeler') THEN
            UPDATE odemeler SET donem = aktif_donem_kod WHERE donem IS NULL;
        END IF;
        
        RAISE NOTICE 'Mevcut kayıtlar aktif döneme atandı: %', aktif_donem_kod;
    ELSE
        RAISE WARNING 'Aktif dönem bulunamadı. Lütfen bir dönem oluşturun ve aktif yapın.';
    END IF;
END $$;

-- İndeks oluşturma (performans için)
CREATE INDEX IF NOT EXISTS idx_bordro_donem ON bordro(donem);
CREATE INDEX IF NOT EXISTS idx_izinler_donem ON izinler(donem);
CREATE INDEX IF NOT EXISTS idx_mesai_donem ON mesai(donem);

-- Eğer odemeler tablosu varsa indeks oluştur
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='odemeler') THEN
        CREATE INDEX IF NOT EXISTS idx_odemeler_donem ON odemeler(donem);
    END IF;
END $$;

-- Script tamamlandı
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DÖNEM YÖNETİMİ KURULUMU TAMAMLANDI!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Aktif dönem: %', (SELECT kod FROM donemler WHERE aktif = TRUE LIMIT 1);
    RAISE NOTICE 'Toplam dönem sayısı: %', (SELECT COUNT(*) FROM donemler);
    RAISE NOTICE '========================================';
END $$;
