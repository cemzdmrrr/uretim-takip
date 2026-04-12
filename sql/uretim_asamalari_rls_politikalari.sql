-- Tüm üretim aşamaları için RLS politikaları

-- 1. Konfeksiyon RLS Politikaları
ALTER TABLE konfeksiyon_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Konfeksiyon kullanıcısı kendi atamalarını görebilir" ON konfeksiyon_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'konfeksiyon'
            AND konfeksiyon_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Konfeksiyon kullanıcısı kendi atamalarını güncelleyebilir" ON konfeksiyon_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'konfeksiyon'
            AND konfeksiyon_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin konfeksiyon atamalarını yönetebilir" ON konfeksiyon_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- 2. Yıkama RLS Politikaları
ALTER TABLE yikama_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Yıkama kullanıcısı kendi atamalarını görebilir" ON yikama_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'yikama'
            AND yikama_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Yıkama kullanıcısı kendi atamalarını güncelleyebilir" ON yikama_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'yikama'
            AND yikama_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin yıkama atamalarını yönetebilir" ON yikama_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- 3. Ütü RLS Politikaları
ALTER TABLE utu_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ütü kullanıcısı kendi atamalarını görebilir" ON utu_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'utu'
            AND utu_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Ütü kullanıcısı kendi atamalarını güncelleyebilir" ON utu_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'utu'
            AND utu_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin ütü atamalarını yönetebilir" ON utu_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- 4. İlik Düğme RLS Politikaları
ALTER TABLE ilik_dugme_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "İlik düğme kullanıcısı kendi atamalarını görebilir" ON ilik_dugme_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'ilik_dugme'
            AND ilik_dugme_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "İlik düğme kullanıcısı kendi atamalarını güncelleyebilir" ON ilik_dugme_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'ilik_dugme'
            AND ilik_dugme_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin ilik düğme atamalarını yönetebilir" ON ilik_dugme_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- 5. Kalite Kontrol RLS Politikaları
ALTER TABLE kalite_kontrol_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kalite kontrol kullanıcısı kendi atamalarını görebilir" ON kalite_kontrol_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'kalite_kontrol'
            AND kalite_kontrol_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Kalite kontrol kullanıcısı kendi atamalarını güncelleyebilir" ON kalite_kontrol_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'kalite_kontrol'
            AND kalite_kontrol_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin kalite kontrol atamalarını yönetebilir" ON kalite_kontrol_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );

-- 6. Paketleme RLS Politikaları
ALTER TABLE paketleme_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Paketleme kullanıcısı kendi atamalarını görebilir" ON paketleme_atamalari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'paketleme'
            AND paketleme_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Paketleme kullanıcısı kendi atamalarını güncelleyebilir" ON paketleme_atamalari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'paketleme'
            AND paketleme_atamalari.atanan_kullanici_id = auth.uid()
        )
    );

CREATE POLICY "Admin paketleme atamalarını yönetebilir" ON paketleme_atamalari
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role IN ('admin', 'ik', 'user')
        )
    );
