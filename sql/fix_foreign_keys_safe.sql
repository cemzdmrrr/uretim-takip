-- GUVENLI FOREIGN KEY EKLEME SCRIPT'I
-- Sadece eksik olanları ekler, mevcut olanları dokunmaz

BEGIN;

-- Yetim kayıtları temizle (sadece çok açık olanlar)
-- Bu adımları atlayabiliriz, sadece constraint'leri deneyelim

-- 1. En basit foreign key'leri ekle (sadece yoksa)
DO $$ 
BEGIN
    -- iplik_stoklari -> tedarikciler
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_stoklari' 
        AND constraint_name = 'iplik_stoklari_tedarikci_id_fkey'
    ) THEN
        ALTER TABLE iplik_stoklari
        ADD CONSTRAINT iplik_stoklari_tedarikci_id_fkey 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        RAISE NOTICE 'iplik_stoklari foreign key eklendi';
    ELSE
        RAISE NOTICE 'iplik_stoklari foreign key zaten mevcut';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'iplik_stoklari foreign key hatasi: %', SQLERRM;
END $$;

-- 2. user_roles -> atolyeler
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_roles' 
        AND constraint_name = 'user_roles_atolye_id_fkey'
    ) THEN
        ALTER TABLE user_roles
        ADD CONSTRAINT user_roles_atolye_id_fkey 
        FOREIGN KEY (atolye_id) REFERENCES atolyeler(id);
        RAISE NOTICE 'user_roles foreign key eklendi';
    ELSE
        RAISE NOTICE 'user_roles foreign key zaten mevcut';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'user_roles foreign key hatasi: %', SQLERRM;
END $$;

-- 3. bildirimler -> auth.users
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'bildirimler' 
        AND constraint_name = 'bildirimler_user_id_fkey'
    ) THEN
        ALTER TABLE bildirimler
        ADD CONSTRAINT bildirimler_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id);
        RAISE NOTICE 'bildirimler foreign key eklendi';
    ELSE
        RAISE NOTICE 'bildirimler foreign key zaten mevcut';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'bildirimler foreign key hatasi: %', SQLERRM;
END $$;

-- 4. atolye_kapasite_takip -> atolyeler
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'atolye_kapasite_takip' 
        AND constraint_name = 'atolye_kapasite_takip_atolye_id_fkey'
    ) THEN
        ALTER TABLE atolye_kapasite_takip
        ADD CONSTRAINT atolye_kapasite_takip_atolye_id_fkey 
        FOREIGN KEY (atolye_id) REFERENCES atolyeler(id);
        RAISE NOTICE 'atolye_kapasite_takip foreign key eklendi';
    ELSE
        RAISE NOTICE 'atolye_kapasite_takip foreign key zaten mevcut';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'atolye_kapasite_takip foreign key hatasi: %', SQLERRM;
END $$;

COMMIT;

-- Sonuc
SELECT 'Guvenli foreign key ekleme tamamlandi' as durum;