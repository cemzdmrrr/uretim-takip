-- SQL SYNTAX TEST DOSYASI
-- Bu dosya PostgreSQL/Supabase'de calisip calismayacagini test etmek icin

-- Test 1: Tablo olusturma
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Test 2: Kolon ekleme (guvenli yontem)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'test_table' AND column_name = 'email'
    ) THEN
        ALTER TABLE test_table ADD COLUMN email VARCHAR(255);
    END IF;
END $$;

-- Test 3: Constraint ekleme (guvenli yontem)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'unique_test_email' AND table_name = 'test_table'
    ) THEN
        ALTER TABLE test_table ADD CONSTRAINT unique_test_email UNIQUE (email);
    END IF;
END $$;

-- Test 4: Test verisini temizle
DROP TABLE IF EXISTS test_table;

-- Basari mesaji
DO $$
BEGIN
    RAISE NOTICE 'SQL syntax testi basarili!';
END $$;
