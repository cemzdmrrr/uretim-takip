-- Politika kontrol ve temizleme scripti

-- 1. Mevcut politikaları listele
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari')
ORDER BY tablename, policyname;

-- 2. RLS durumunu kontrol et
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari');

-- 3. Tüm mevcut politikaları sil (önce bu kodu çalıştırın)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Dosyalar tablosu politikalarını sil
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosyalar') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosyalar';
    END LOOP;
    
    -- Dosya paylaşımları tablosu politikalarını sil
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosya_paylasimlari') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosya_paylasimlari';
    END LOOP;
    
    RAISE NOTICE 'Tüm politikalar silindi';
END $$;

-- 4. RLS'yi yeniden etkinleştir
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;
