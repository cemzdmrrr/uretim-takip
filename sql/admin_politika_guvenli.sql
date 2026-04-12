-- Admin rolüne tüm yetkileri veren güvenli politikalar
-- Bu script tabloların varlığını kontrol eder ve sadece var olan tablolara politika uygular

-- Helper function to check if table exists
CREATE OR REPLACE FUNCTION table_exists(table_name text) 
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = $1
    );
END;
$$ LANGUAGE plpgsql;

-- Helper function to apply admin policy
CREATE OR REPLACE FUNCTION apply_admin_policy(table_name text)
RETURNS void AS $$
BEGIN
    IF table_exists(table_name) THEN
        -- Drop existing admin policy
        EXECUTE format('DROP POLICY IF EXISTS "Admin tüm %I verilerine erişebilir" ON public.%I', table_name, table_name);
        
        -- Create new admin policy
        EXECUTE format('
            CREATE POLICY "Admin tüm %I verilerine erişebilir" ON public.%I
            FOR ALL USING (
                EXISTS(
                    SELECT 1 FROM public.user_roles ur 
                    WHERE ur.user_id = auth.uid() 
                    AND ur.role = ''admin''
                )
            )
            WITH CHECK (
                EXISTS(
                    SELECT 1 FROM public.user_roles ur 
                    WHERE ur.user_id = auth.uid() 
                    AND ur.role = ''admin''
                )
            )', table_name, table_name);
            
        RAISE NOTICE 'Admin politikası uygulandı: %', table_name;
    ELSE
        RAISE NOTICE 'Tablo bulunamadı, atlandı: %', table_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Core tables
SELECT apply_admin_policy('user_roles');
SELECT apply_admin_policy('modeller');
SELECT apply_admin_policy('personel');
SELECT apply_admin_policy('tedarikciler');
SELECT apply_admin_policy('faturalar');
SELECT apply_admin_policy('kasa_banka');
SELECT apply_admin_policy('kasa_banka_hareketleri');
SELECT apply_admin_policy('dosyalar');
SELECT apply_admin_policy('ayarlar');
SELECT apply_admin_policy('donemler');

-- Production stage tables
SELECT apply_admin_policy('dokuma_atamalari');
SELECT apply_admin_policy('konfeksiyon_atamalari');
SELECT apply_admin_policy('yikama_atamalari');
SELECT apply_admin_policy('utu_atamalari');
SELECT apply_admin_policy('ilik_dugme_atamalari');
SELECT apply_admin_policy('kalite_kontrol_atamalari');
SELECT apply_admin_policy('paketleme_atamalari');

-- Inventory and accessories
SELECT apply_admin_policy('aksesuarlar');
SELECT apply_admin_policy('iplik_siparisler');
SELECT apply_admin_policy('iplik_siparis_takip');
SELECT apply_admin_policy('teslimatlar');
SELECT apply_admin_policy('stok_hareketleri');

-- Reports and HR
SELECT apply_admin_policy('rapor_verileri');
SELECT apply_admin_policy('izinler');
SELECT apply_admin_policy('mesailer');
SELECT apply_admin_policy('bordro');
SELECT apply_admin_policy('odemeler');

-- Additional tables that might exist
SELECT apply_admin_policy('personel_arsiv');
SELECT apply_admin_policy('personel_donem');
SELECT apply_admin_policy('tedarikci_siparisleri');
SELECT apply_admin_policy('tedarikci_odemeleri');
SELECT apply_admin_policy('musteri_siparisleri');
SELECT apply_admin_policy('musteri_odemeleri');
SELECT apply_admin_policy('puantaj');
SELECT apply_admin_policy('maaslar');
SELECT apply_admin_policy('avanslar');
SELECT apply_admin_policy('kesintiler');

-- Clean up helper functions
DROP FUNCTION IF EXISTS apply_admin_policy(text);
DROP FUNCTION IF EXISTS table_exists(text);

-- Final verification
SELECT 
    'Admin politikaları başarıyla uygulandı!' as message,
    COUNT(*) as toplam_politika_sayisi
FROM pg_policies 
WHERE schemaname = 'public'
AND (policyname LIKE '%Admin%' OR policyname LIKE '%admin%');
