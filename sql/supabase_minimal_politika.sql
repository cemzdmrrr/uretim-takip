-- EN MİNİMAL POLİTİKALAR - SADECE TEMEL ERİŞİM

-- RLS'yi etkinleştir
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;

-- TÜM POLİTİKALARI SİL
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosyalar') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosyalar';
    END LOOP;
    
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'dosya_paylasimlari') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON dosya_paylasimlari';
    END LOOP;
END $$;

-- EN BASIT POLİTİKALAR
-- Dosyalar için
CREATE POLICY dosyalar_all ON dosyalar FOR ALL USING (true);
CREATE POLICY dosya_paylasimlari_all ON dosya_paylasimlari FOR ALL USING (true);

-- Kontrol
SELECT tablename, policyname FROM pg_policies 
WHERE tablename IN ('dosyalar', 'dosya_paylasimlari');
