-- Admin kullanıcısı için RLS politikalarını düzelt

-- 1. Admin kullanıcı ID'sini kontrol et
SELECT id, email, role FROM auth.users WHERE email = 'planlama@akarorme.com';

-- 2. Mevcut politikaları kontrol et
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('dokuma_atamalari', 'konfeksiyon_atamalari', 'nakis_atamalari', 'yikama_atamalari', 'ilik_dugme_atamalari', 'utu_atamalari')
ORDER BY tablename, policyname;

-- 3. Admin kullanıcısı için tüm tabloları görebilme politikası ekle
-- Dokuma atamaları için admin politikası
DROP POLICY IF EXISTS "admin_full_access_dokuma" ON dokuma_atamalari;
CREATE POLICY "admin_full_access_dokuma" ON dokuma_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Konfeksiyon atamaları için admin politikası
DROP POLICY IF EXISTS "admin_full_access_konfeksiyon" ON konfeksiyon_atamalari;
CREATE POLICY "admin_full_access_konfeksiyon" ON konfeksiyon_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Nakış atamaları için admin politikası (varsa)
DROP POLICY IF EXISTS "admin_full_access_nakis" ON nakis_atamalari;
CREATE POLICY "admin_full_access_nakis" ON nakis_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Yıkama atamaları için admin politikası
DROP POLICY IF EXISTS "admin_full_access_yikama" ON yikama_atamalari;
CREATE POLICY "admin_full_access_yikama" ON yikama_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- İlik düğme atamaları için admin politikası
DROP POLICY IF EXISTS "admin_full_access_ilik_dugme" ON ilik_dugme_atamalari;
CREATE POLICY "admin_full_access_ilik_dugme" ON ilik_dugme_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Ütü atamaları için admin politikası
DROP POLICY IF EXISTS "admin_full_access_utu" ON utu_atamalari;
CREATE POLICY "admin_full_access_utu" ON utu_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 4. Kalite kontrol tablosu için admin politikası
DROP POLICY IF EXISTS "admin_full_access_kalite" ON kalite_kontrol_atamalari;
CREATE POLICY "admin_full_access_kalite" ON kalite_kontrol_atamalari
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 5. Test sorguları - admin kullanıcısı ile test et
SELECT 'Dokuma atamaları:' as tablo, count(*) as toplam FROM dokuma_atamalari;
SELECT 'Konfeksiyon atamaları:' as tablo, count(*) as toplam FROM konfeksiyon_atamalari;
SELECT 'Kalite kontrol atamaları:' as tablo, count(*) as toplam FROM kalite_kontrol_atamalari;

-- 6. Kullanıcı rolünü kontrol et
SELECT ur.role, u.email 
FROM user_roles ur 
JOIN auth.users u ON ur.user_id = u.id 
WHERE u.email = 'planlama@akarorme.com';