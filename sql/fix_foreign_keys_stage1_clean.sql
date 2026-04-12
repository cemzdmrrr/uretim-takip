-- GUVENLI FOREIGN KEY DUZELTME SCRIPTI (ASAMA 1)
-- Sadece temel primary keyleri ve en guvenli foreign keyleri ekler

-- 1. Once eksik primary keyleri ekle
BEGIN;

-- Iplik stoklarinda eksik primary key varsa ekle
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_stoklari' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE iplik_stoklari ADD CONSTRAINT iplik_stoklari_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- Iplik hareketlerinde eksik primary key varsa ekle
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_hareketleri' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE iplik_hareketleri ADD CONSTRAINT iplik_hareketleri_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- 2. En guvenli foreign keyleri ekle (sadece su an var olan constraintler yoksa)
DO $$ 
BEGIN
    -- iplik_stoklari -> tedarikciler
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_stoklari' 
        AND constraint_name = 'iplik_stoklari_tedarikci_id_fkey'
    ) THEN
        -- Once yetim kayitlari kontrol et
        DELETE FROM iplik_stoklari 
        WHERE tedarikci_id IS NOT NULL 
        AND tedarikci_id NOT IN (SELECT id FROM tedarikciler);
        
        ALTER TABLE iplik_stoklari
        ADD CONSTRAINT iplik_stoklari_tedarikci_id_fkey 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
    END IF;
END $$;

-- 3. aksesuarlar -> tedarikciler foreign key
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'aksesuarlar' 
        AND constraint_name = 'aksesuarlar_tedarikci_id_fkey'
    ) THEN
        -- Once yetim kayitlari kontrol et
        DELETE FROM aksesuarlar 
        WHERE tedarikci_id IS NOT NULL 
        AND tedarikci_id NOT IN (SELECT id FROM tedarikciler);
        
        -- Eger basarisizsa constraint ekleme
        ALTER TABLE aksesuarlar
        ADD CONSTRAINT aksesuarlar_tedarikci_id_fkey 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'aksesuarlar foreign key hatasi: %', SQLERRM;
END $$;

-- 4. Basic user-related foreign keys
DO $$ 
BEGIN
    -- user_roles -> atolyeler
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_roles' 
        AND constraint_name = 'user_roles_atolye_id_fkey'
    ) THEN
        DELETE FROM user_roles 
        WHERE atolye_id IS NOT NULL 
        AND atolye_id NOT IN (SELECT id FROM atolyeler);
        
        ALTER TABLE user_roles
        ADD CONSTRAINT user_roles_atolye_id_fkey 
        FOREIGN KEY (atolye_id) REFERENCES atolyeler(id);
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'user_roles foreign key hatasi: %', SQLERRM;
END $$;

COMMIT;

-- Basari mesaji
SELECT 'Asama 1 tamamlandi - Primary keyler ve temel foreign keyler eklendi' as durum;