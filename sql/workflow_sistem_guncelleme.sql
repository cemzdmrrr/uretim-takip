-- İstenen iş akışı için veritabanı şeması güncellemeleri
-- Admin → Firma ataması → Firma onayı → Üretim → Kalite → Sevkiyat workflow'u

-- 1. Mevcut uretim_kayitlari tablosuna gerekli sütunları ekle
DO $$
BEGIN
    -- Firma onay durumu için yeni sütunlar
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'atama_durumu'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN atama_durumu TEXT DEFAULT 'beklemede' 
        CHECK (atama_durumu IN ('beklemede', 'firma_onay_bekliyor', 'onaylandi', 'reddedildi', 'uretimde', 'tamamlandi'));
        RAISE NOTICE '✓ atama_durumu sütunu eklendi';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_onay_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_onay_tarihi TIMESTAMPTZ;
        RAISE NOTICE '✓ firma_onay_tarihi sütunu eklendi';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'firma_red_nedeni'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN firma_red_nedeni TEXT;
        RAISE NOTICE '✓ firma_red_nedeni sütunu eklendi';
    END IF;

    -- Üretim başlatma ve tamamlama için
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'uretim_baslangic_tarihi'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN uretim_baslangic_tarihi TIMESTAMPTZ;
        RAISE NOTICE '✓ uretim_baslangic_tarihi sütunu eklendi';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'uretilen_adet'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN uretilen_adet INTEGER DEFAULT 0 CHECK (uretilen_adet >= 0);
        RAISE NOTICE '✓ uretilen_adet sütunu eklendi';
    END IF;

    -- Atama yapan admin bilgisi
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'uretim_kayitlari' 
        AND column_name = 'atama_yapan_user_id'
    ) THEN
        ALTER TABLE uretim_kayitlari 
        ADD COLUMN atama_yapan_user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✓ atama_yapan_user_id sütunu eklendi';
    END IF;

    RAISE NOTICE 'Tüm gerekli sütunlar uretim_kayitlari tablosuna eklendi';
END $$;

-- 2. Bildirimler tablosunu güncelle
DO $$
BEGIN
    -- Bildirim türleri için daha detaylı enum
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'bildirimler' AND constraint_name = 'bildirimler_tip_check'
    ) THEN
        ALTER TABLE bildirimler DROP CONSTRAINT bildirimler_tip_check;
    END IF;

    ALTER TABLE bildirimler 
    ADD CONSTRAINT bildirimler_tip_check 
    CHECK (tip IN (
        'atama_bekliyor',          -- Firmaya atama yapıldı, onay bekliyor
        'atama_onaylandi',         -- Firma atamayı onayladı
        'atama_reddedildi',        -- Firma atamayı reddetti
        'uretim_tamamlandi',       -- Firma üretimi tamamladı, kaliteye gidiyor
        'kalite_onay',             -- Kalite güvence onayı
        'kalite_red',              -- Kalite güvence reddi
        'sevkiyat_hazir',          -- Sevkiyata hazır
        'genel'                    -- Diğer
    ));

    -- Bildirimde atama bilgisi için sütun
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bildirimler' 
        AND column_name = 'atama_id'
    ) THEN
        ALTER TABLE bildirimler 
        ADD COLUMN atama_id UUID REFERENCES uretim_kayitlari(id) ON DELETE CASCADE;
        RAISE NOTICE '✓ atama_id sütunu eklendi';
    END IF;

    RAISE NOTICE 'bildirimler tablosu güncellendi';
END $$;

-- 3. User roles tablosunu temizle ve basitleştir
DO $$
BEGIN
    -- Önce mevcut constraint'i kaldır
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_roles' AND constraint_name = 'user_roles_role_check'
    ) THEN
        ALTER TABLE user_roles DROP CONSTRAINT user_roles_role_check;
    END IF;

    -- Tüm rolleri standart rollere dönüştür
    UPDATE user_roles SET role = 'user' WHERE role NOT IN ('admin', 'ik', 'personel');
    UPDATE user_roles SET role = 'admin' WHERE role IN ('yonetici', 'administrator');
    UPDATE user_roles SET role = 'personel' WHERE role IN ('calisan', 'işçi', 'worker');

    -- Basit constraint ekle
    ALTER TABLE user_roles 
    ADD CONSTRAINT user_roles_role_check 
    CHECK (role IN ('admin', 'user', 'ik', 'personel'));

    RAISE NOTICE '✓ user_roles tablosu basitleştirildi';
END $$;

-- 4. Firma kullanıcıları için ayrı tablo oluştur
CREATE TABLE IF NOT EXISTS firma_kullanicilari (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    firma_id INTEGER REFERENCES atolyeler(id) ON DELETE CASCADE,
    firma_turu TEXT NOT NULL CHECK (firma_turu IN (
        'dokuma_firmasi',
        'konfeksiyon_firmasi', 
        'nakis_firmasi',
        'yikama_firmasi',
        'utu_firmasi',
        'ilik_dugme_firmasi'
    )),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, firma_id)
);

-- 5. Özel personel için ayrı tablo oluştur
CREATE TABLE IF NOT EXISTS ozel_personel (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    personel_turu TEXT NOT NULL CHECK (personel_turu IN (
        'kalite_guvence',
        'sevkiyat_personeli',
        'muhasebe',
        'satis',
        'tasarim', 
        'planlama',
        'depo'
    )),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, personel_turu)
);

-- 6. Atama durumu güncelleme trigger'ı (güncellenmiş)
CREATE OR REPLACE FUNCTION uretim_kaydi_durum_guncelle()
RETURNS TRIGGER AS $$
BEGIN
    -- Atama durumu değiştiğinde bildirim gönder
    IF TG_OP = 'UPDATE' THEN
        -- Firma onayı bildirimi
        IF NEW.atama_durumu = 'onaylandi' AND OLD.atama_durumu = 'firma_onay_bekliyor' THEN
            -- Admin'e firma onayını bildır
            INSERT INTO bildirimler (user_id, baslik, mesaj, tip, model_id, atama_id)
            SELECT 
                NEW.atama_yapan_user_id,
                'Firma Onayı Alındı',
                'Dokuma firması atamayı onayladı. Üretim başlatılabilir.',
                'atama_onaylandi',
                NEW.model_id,
                NEW.id
            WHERE NEW.atama_yapan_user_id IS NOT NULL;
        
        ELSIF NEW.atama_durumu = 'reddedildi' AND OLD.atama_durumu = 'firma_onay_bekliyor' THEN
            -- Admin'e firma reddi bildirimi
            INSERT INTO bildirimler (user_id, baslik, mesaj, tip, model_id, atama_id)
            SELECT 
                NEW.atama_yapan_user_id,
                'Firma Atamayı Reddetti',
                'Dokuma firması atamayı reddetti. Sebep: ' || COALESCE(NEW.firma_red_nedeni, 'Belirtilmemiş'),
                'atama_reddedildi',
                NEW.model_id,
                NEW.id
            WHERE NEW.atama_yapan_user_id IS NOT NULL;
        
        ELSIF NEW.atama_durumu = 'tamamlandi' AND OLD.atama_durumu = 'uretimde' THEN
            -- Kalite güvence personeline bildirim (yeni tablo yapısı)
            INSERT INTO bildirimler (user_id, baslik, mesaj, tip, model_id, atama_id)
            SELECT 
                op.user_id,
                'Üretim Tamamlandı - Kalite Kontrolü',
                'Üretim tamamlandı. ' || NEW.uretilen_adet || ' adet kalite kontrol bekliyor.',
                'uretim_tamamlandi',
                NEW.model_id,
                NEW.id
            FROM ozel_personel op 
            WHERE op.personel_turu = 'kalite_guvence' AND op.aktif = true;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger oluştur
DROP TRIGGER IF EXISTS trigger_uretim_durum_guncelle ON uretim_kayitlari;
CREATE TRIGGER trigger_uretim_durum_guncelle
    AFTER UPDATE ON uretim_kayitlari
    FOR EACH ROW
    EXECUTE FUNCTION uretim_kaydi_durum_guncelle();

-- 7. İndexler oluştur
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_atama_durumu ON uretim_kayitlari(atama_durumu);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_firma_onay_tarihi ON uretim_kayitlari(firma_onay_tarihi);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_atama_yapan ON uretim_kayitlari(atama_yapan_user_id);
CREATE INDEX IF NOT EXISTS idx_bildirimler_atama_id ON bildirimler(atama_id);
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_user_id ON firma_kullanicilari(user_id);
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_firma_id ON firma_kullanicilari(firma_id);
CREATE INDEX IF NOT EXISTS idx_ozel_personel_user_id ON ozel_personel(user_id);
CREATE INDEX IF NOT EXISTS idx_ozel_personel_turu ON ozel_personel(personel_turu);

-- 8. RLS politikaları güncelle (yeni tablo yapısına göre)
-- Firma kullanıcıları kendi atamalarını görebilir ve güncelleyebilir
DROP POLICY IF EXISTS "Firma kullanıcıları kendi atamalarını görebilir" ON uretim_kayitlari;
CREATE POLICY "Firma kullanıcıları kendi atamalarını görebilir" ON uretim_kayitlari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM firma_kullanicilari fk 
            WHERE fk.user_id = auth.uid() 
            AND fk.firma_id = uretim_kayitlari.firma_id
            AND fk.aktif = true
        ) OR
        -- Admin kullanıcıları görebilir
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        ) OR
        -- Kalite ve sevkiyat personeli görebilir
        EXISTS (
            SELECT 1 FROM ozel_personel op 
            WHERE op.user_id = auth.uid() 
            AND op.personel_turu IN ('kalite_guvence', 'sevkiyat_personeli')
            AND op.aktif = true
        )
    );

DROP POLICY IF EXISTS "Firma kullanıcıları kendi atamalarını güncelleyebilir" ON uretim_kayitlari;
CREATE POLICY "Firma kullanıcıları kendi atamalarını güncelleyebilir" ON uretim_kayitlari
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM firma_kullanicilari fk 
            WHERE fk.user_id = auth.uid() 
            AND fk.firma_id = uretim_kayitlari.firma_id
            AND fk.aktif = true
        ) OR
        -- Admin kullanıcıları güncelleyebilir
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        ) OR
        -- Kalite ve sevkiyat personeli güncelleyebilir
        EXISTS (
            SELECT 1 FROM ozel_personel op 
            WHERE op.user_id = auth.uid() 
            AND op.personel_turu IN ('kalite_guvence', 'sevkiyat_personeli')
            AND op.aktif = true
        )
    );

-- Yeni tablolar için RLS politikaları
ALTER TABLE firma_kullanicilari ENABLE ROW LEVEL SECURITY;
ALTER TABLE ozel_personel ENABLE ROW LEVEL SECURITY;

-- Firma kullanıcıları tablosu politikaları
CREATE POLICY "Admin ve ilgili kullanıcılar firma kullanıcılarını görebilir" ON firma_kullanicilari
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        ) OR
        user_id = auth.uid()
    );

-- Özel personel tablosu politikaları  
CREATE POLICY "Admin ve ilgili kullanıcılar özel personeli görebilir" ON ozel_personel
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles ur 
            WHERE ur.user_id = auth.uid() 
            AND ur.role = 'admin'
        ) OR
        user_id = auth.uid()
    );

-- 9. Test verileri ekle (opsiyonel)
-- Bu kısmı sadece test için kullanın
/*
-- Test admin kullanıcısı oluştur
INSERT INTO user_roles (user_id, role, aktif) 
VALUES (auth.uid(), 'admin', true) 
ON CONFLICT (user_id) DO UPDATE SET role = 'admin', aktif = true;

-- Test dokuma firması oluştur
INSERT INTO atolyeler (atolye_adi, atolye_turu, aktif) 
VALUES ('Test Dokuma Firması', 'Dokuma', true) 
ON CONFLICT DO NOTHING;

-- Test firma kullanıcısı oluştur
INSERT INTO firma_kullanicilari (user_id, firma_id, firma_turu) 
SELECT auth.uid(), a.id, 'dokuma_firmasi'
FROM atolyeler a 
WHERE a.atolye_adi = 'Test Dokuma Firması'
ON CONFLICT DO NOTHING;

-- Test kalite personeli oluştur  
INSERT INTO ozel_personel (user_id, personel_turu)
VALUES (auth.uid(), 'kalite_guvence')
ON CONFLICT DO NOTHING;
*/

-- 10. Başarılı tamamlama mesajı
SELECT 'Workflow sistemi başarıyla güncellendi!' as sonuc;
SELECT 'Yeni sütunlar: atama_durumu, firma_onay_tarihi, firma_red_nedeni, uretim_baslangic_tarihi, uretilen_adet, atama_yapan_user_id' as eklenen_sutunlar;
SELECT 'Yeni tablolar: firma_kullanicilari, ozel_personel (roller ayrı tablolarda)' as yeni_tablolar;
SELECT 'user_roles tablosu basitleştirildi: sadece admin, user, ik, personel' as basitlestirme;