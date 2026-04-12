-- Dosyalar tablosu ve ilgili yapılar

-- 1. Dosyalar tablosu
CREATE TABLE IF NOT EXISTS dosyalar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ad VARCHAR(255) NOT NULL,
    dosya_turu VARCHAR(20) DEFAULT 'pdf' CHECK (dosya_turu IN ('pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'folder')),
    boyut BIGINT DEFAULT 0, -- byte cinsinden
    yol TEXT NOT NULL, -- Supabase Storage path
    ust_klasor_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE, -- Klasör yapısı için
    aciklama TEXT,
    etiketler TEXT[], -- Dosya etiketleri
    olusturan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    duzenleyen_kullanici_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    silinme_tarihi TIMESTAMP WITH TIME ZONE, -- Soft delete için
    aktif BOOLEAN DEFAULT true,
    genel_erisim BOOLEAN DEFAULT false, -- Herkese açık mı
    izinli_kullanicilar UUID[], -- Erişim izni olan kullanıcılar
    son_erisim_tarihi TIMESTAMP WITH TIME ZONE,
    erisim_sayisi INTEGER DEFAULT 0,
    
    -- Dosya metadata
    mime_type VARCHAR(100),
    hash_deger VARCHAR(64), -- Dosya bütünlüğü kontrolü için
    versiyon INTEGER DEFAULT 1,
    ana_dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE, -- Versiyon kontrolü için
    
    -- Indexler için
    CONSTRAINT unique_yol_aktif UNIQUE (yol, aktif) DEFERRABLE
);

-- 2. Dosya paylaşımları tablosu
CREATE TABLE IF NOT EXISTS dosya_paylasimlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    paylasan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    hedef_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    izin_turu VARCHAR(20) DEFAULT 'read' CHECK (izin_turu IN ('read', 'write', 'admin')),
    paylasim_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    son_kullanma_tarihi TIMESTAMP WITH TIME ZONE,
    aktif BOOLEAN DEFAULT true,
    
    CONSTRAINT unique_dosya_kullanici_paylanim UNIQUE (dosya_id, hedef_kullanici_id)
);

-- 3. Dosya geçmişi tablosu (versiyon kontrolü)
CREATE TABLE IF NOT EXISTS dosya_gecmisi (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    islem_turu VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'rename', 'move', 'share'
    eski_deger JSONB,
    yeni_deger JSONB,
    kullanici_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    islem_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_adresi INET,
    kullanici_agent TEXT
);

-- 4. Dosya yorumları tablosu
CREATE TABLE IF NOT EXISTS dosya_yorumlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    yorum TEXT NOT NULL,
    ust_yorum_id UUID REFERENCES dosya_yorumlari(id) ON DELETE CASCADE,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true
);

-- 5. Indexler
CREATE INDEX IF NOT EXISTS idx_dosyalar_ust_klasor ON dosyalar(ust_klasor_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_olusturan ON dosyalar(olusturan_kullanici_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_dosya_turu ON dosyalar(dosya_turu) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_olusturma_tarihi ON dosyalar(olusturma_tarihi DESC) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_ad ON dosyalar USING gin(to_tsvector('turkish', ad)) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_etiketler ON dosyalar USING gin(etiketler) WHERE aktif = true;

CREATE INDEX IF NOT EXISTS idx_dosya_paylasimlari_dosya ON dosya_paylasimlari(dosya_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosya_paylasimlari_hedef ON dosya_paylasimlari(hedef_kullanici_id) WHERE aktif = true;

CREATE INDEX IF NOT EXISTS idx_dosya_gecmisi_dosya ON dosya_gecmisi(dosya_id);
CREATE INDEX IF NOT EXISTS idx_dosya_gecmisi_tarih ON dosya_gecmisi(islem_tarihi DESC);

CREATE INDEX IF NOT EXISTS idx_dosya_yorumlari_dosya ON dosya_yorumlari(dosya_id) WHERE aktif = true;

-- 6. Trigger'lar
-- Güncelleme tarihi otomatik güncellemesi
CREATE OR REPLACE FUNCTION update_guncelleme_tarihi()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dosyalar_guncelleme_tarihi
    BEFORE UPDATE ON dosyalar
    FOR EACH ROW
    EXECUTE FUNCTION update_guncelleme_tarihi();

CREATE TRIGGER dosya_yorumlari_guncelleme_tarihi
    BEFORE UPDATE ON dosya_yorumlari
    FOR EACH ROW
    EXECUTE FUNCTION update_guncelleme_tarihi();

-- Dosya geçmişi kaydı
CREATE OR REPLACE FUNCTION dosya_gecmis_kayit()
RETURNS TRIGGER AS $$
BEGIN
    -- RLS politikalarını bypass etmek için security definer kullan
    SET LOCAL row_security = off;
    
    IF TG_OP = 'INSERT' THEN
        INSERT INTO dosya_gecmisi (dosya_id, islem_turu, yeni_deger, kullanici_id)
        VALUES (NEW.id, 'create', to_jsonb(NEW), NEW.olusturan_kullanici_id);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO dosya_gecmisi (dosya_id, islem_turu, eski_deger, yeni_deger, kullanici_id)
        VALUES (NEW.id, 'update', to_jsonb(OLD), to_jsonb(NEW), NEW.duzenleyen_kullanici_id);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO dosya_gecmisi (dosya_id, islem_turu, eski_deger, kullanici_id)
        VALUES (OLD.id, 'delete', to_jsonb(OLD), COALESCE(OLD.duzenleyen_kullanici_id, OLD.olusturan_kullanici_id));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER dosyalar_gecmis_trigger
    AFTER INSERT OR UPDATE OR DELETE ON dosyalar
    FOR EACH ROW
    EXECUTE FUNCTION dosya_gecmis_kayit();

-- 7. RLS (Row Level Security) Politikaları
ALTER TABLE dosyalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_paylasimlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_gecmisi ENABLE ROW LEVEL SECURITY;
ALTER TABLE dosya_yorumlari ENABLE ROW LEVEL SECURITY;

-- Dosyalar için RLS politikaları
-- Okuma izni: Dosya sahibi, paylaşılan kullanıcılar veya genel erişimi olan dosyalar
CREATE POLICY dosyalar_select_policy ON dosyalar
    FOR SELECT
    USING (
        aktif = true AND (
            olusturan_kullanici_id = auth.uid() OR
            genel_erisim = true OR
            auth.uid() = ANY(izinli_kullanicilar) OR
            EXISTS (
                SELECT 1 FROM dosya_paylasimlari dp
                WHERE dp.dosya_id = id 
                AND dp.hedef_kullanici_id = auth.uid() 
                AND dp.aktif = true
                AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
            )
        )
    );

-- Ekleme izni: Sadece giriş yapmış kullanıcılar
CREATE POLICY dosyalar_insert_policy ON dosyalar
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Güncelleme izni: Dosya sahibi veya yazma iznine sahip kullanıcılar
CREATE POLICY dosyalar_update_policy ON dosyalar
    FOR UPDATE
    USING (
        aktif = true AND (
            olusturan_kullanici_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM dosya_paylasimlari dp
                WHERE dp.dosya_id = id 
                AND dp.hedef_kullanici_id = auth.uid() 
                AND dp.izin_turu IN ('write', 'admin')
                AND dp.aktif = true
                AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
            )
        )
    );

-- Silme izni: Sadece dosya sahibi veya admin iznine sahip kullanıcılar
CREATE POLICY dosyalar_delete_policy ON dosyalar
    FOR DELETE
    USING (
        olusturan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.izin_turu = 'admin'
            AND dp.aktif = true
            AND (dp.son_kullanma_tarihi IS NULL OR dp.son_kullanma_tarihi > NOW())
        )
    );

-- Dosya paylaşımları için RLS politikaları
CREATE POLICY dosya_paylasimlari_select_policy ON dosya_paylasimlari
    FOR SELECT
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

CREATE POLICY dosya_paylasimlari_insert_policy ON dosya_paylasimlari
    FOR INSERT
    WITH CHECK (
        paylasan_kullanici_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND (d.olusturan_kullanici_id = auth.uid() OR 
                 EXISTS (
                     SELECT 1 FROM dosya_paylasimlari dp2
                     WHERE dp2.dosya_id = d.id 
                     AND dp2.hedef_kullanici_id = auth.uid() 
                     AND dp2.izin_turu IN ('write', 'admin')
                 ))
        )
    );

CREATE POLICY dosya_paylasimlari_update_policy ON dosya_paylasimlari
    FOR UPDATE
    USING (paylasan_kullanici_id = auth.uid());

CREATE POLICY dosya_paylasimlari_delete_policy ON dosya_paylasimlari
    FOR DELETE
    USING (
        paylasan_kullanici_id = auth.uid() OR 
        hedef_kullanici_id = auth.uid()
    );

-- Dosya geçmişi: Sadece okuma, ilgili dosyaya erişimi olan kullanıcılar
CREATE POLICY dosya_gecmisi_select_policy ON dosya_gecmisi
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                d.genel_erisim = true OR
                auth.uid() = ANY(d.izinli_kullanicilar) OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.aktif = true
                )
            )
        )
    );

-- Dosya geçmişi INSERT politikası (trigger için gerekli)
CREATE POLICY dosya_gecmisi_insert_policy ON dosya_gecmisi
    FOR INSERT
    WITH CHECK (true); -- Trigger'lar için serbest INSERT

-- Dosya yorumları için RLS politikaları  
CREATE POLICY dosya_yorumlari_select_policy ON dosya_yorumlari
    FOR SELECT
    USING (
        aktif = true AND
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                d.genel_erisim = true OR
                auth.uid() = ANY(d.izinli_kullanicilar) OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.aktif = true
                )
            )
        )
    );

CREATE POLICY dosya_yorumlari_insert_policy ON dosya_yorumlari
    FOR INSERT
    WITH CHECK (
        kullanici_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM dosyalar d
            WHERE d.id = dosya_id 
            AND (
                d.olusturan_kullanici_id = auth.uid() OR
                d.genel_erisim = true OR
                auth.uid() = ANY(d.izinli_kullanicilar) OR
                EXISTS (
                    SELECT 1 FROM dosya_paylasimlari dp
                    WHERE dp.dosya_id = d.id 
                    AND dp.hedef_kullanici_id = auth.uid() 
                    AND dp.aktif = true
                )
            )
        )
    );

CREATE POLICY dosya_yorumlari_update_policy ON dosya_yorumlari
    FOR UPDATE
    USING (kullanici_id = auth.uid());

CREATE POLICY dosya_yorumlari_delete_policy ON dosya_yorumlari
    FOR DELETE
    USING (kullanici_id = auth.uid());

-- 8. Supabase Storage bucket oluşturma (manuel olarak Supabase dashboard'dan yapılmalı)
-- Bucket adı: 'dosyalar'
-- Public: false
-- Allowed MIME types: application/pdf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document, etc.

-- 9. Storage politikaları (Supabase dashboard'dan eklenmelidir)
/*
-- Storage bucket için RLS politikaları:

-- SELECT (Dosya okuma)
(bucket_id = 'dosyalar'::text) AND 
EXISTS (
    SELECT 1 FROM dosyalar d
    WHERE d.yol = name 
    AND d.aktif = true
    AND (
        d.olusturan_kullanici_id = auth.uid() OR
        d.genel_erisim = true OR
        auth.uid() = ANY(d.izinli_kullanicilar) OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = d.id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.aktif = true
        )
    )
)

-- INSERT (Dosya yükleme)
(bucket_id = 'dosyalar'::text) AND (auth.uid() IS NOT NULL)

-- UPDATE (Dosya güncelleme) 
(bucket_id = 'dosyalar'::text) AND 
EXISTS (
    SELECT 1 FROM dosyalar d
    WHERE d.yol = name 
    AND (
        d.olusturan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = d.id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.izin_turu IN ('write', 'admin')
            AND dp.aktif = true
        )
    )
)

-- DELETE (Dosya silme)
(bucket_id = 'dosyalar'::text) AND 
EXISTS (
    SELECT 1 FROM dosyalar d
    WHERE d.yol = name 
    AND (
        d.olusturan_kullanici_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM dosya_paylasimlari dp
            WHERE dp.dosya_id = d.id 
            AND dp.hedef_kullanici_id = auth.uid() 
            AND dp.izin_turu = 'admin'
            AND dp.aktif = true
        )
    )
)
*/

-- 10. Test verileri (isteğe bağlı)
/*
-- Ana klasör örneği
INSERT INTO dosyalar (ad, dosya_turu, yol, olusturan_kullanici_id) 
VALUES ('Belgeler', 'folder', 'folders/belgeler/', (SELECT id FROM auth.users LIMIT 1));

-- Alt klasör örneği
INSERT INTO dosyalar (ad, dosya_turu, yol, ust_klasor_id, olusturan_kullanici_id) 
VALUES ('Faturalar', 'folder', 'folders/belgeler/faturalar/', 
        (SELECT id FROM dosyalar WHERE ad = 'Belgeler' AND dosya_turu = 'folder'),
        (SELECT id FROM auth.users LIMIT 1));
*/

COMMENT ON TABLE dosyalar IS 'Dosya ve klasör yönetimi için ana tablo';
COMMENT ON COLUMN dosyalar.yol IS 'Supabase Storage bucket içindeki dosya yolu';
COMMENT ON COLUMN dosyalar.ust_klasor_id IS 'Üst klasör referansı (klasör yapısı için)';
COMMENT ON COLUMN dosyalar.hash_deger IS 'Dosya bütünlüğü kontrolü için SHA-256 hash';
COMMENT ON COLUMN dosyalar.ana_dosya_id IS 'Versiyon kontrolü için ana dosya referansı';
