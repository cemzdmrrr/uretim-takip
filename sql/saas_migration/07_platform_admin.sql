-- ============================================================
-- ASAMA 9: PLATFORM YÖNETİM PANELİ (SUPER ADMIN)
-- TexPilot SaaS - Platform Admin Altyapısı
-- ============================================================

-- ---------------------------------------------------------
-- 1. DESTEK TALEPLERİ TABLOSU
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.destek_talepleri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    konu TEXT NOT NULL,
    mesaj TEXT NOT NULL,
    kategori TEXT NOT NULL DEFAULT 'genel',
    oncelik TEXT NOT NULL DEFAULT 'normal',
    durum TEXT NOT NULL DEFAULT 'acik',
    atanan_admin UUID REFERENCES auth.users(id),
    cevap TEXT,
    cevaplayan_id UUID REFERENCES auth.users(id),
    cevap_tarihi TIMESTAMPTZ,
    kapatma_tarihi TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT chk_destek_kategori CHECK (kategori IN ('genel', 'teknik', 'fatura', 'modul', 'hata', 'ozellik_talebi')),
    CONSTRAINT chk_destek_oncelik CHECK (oncelik IN ('dusuk', 'normal', 'yuksek', 'acil')),
    CONSTRAINT chk_destek_durum CHECK (durum IN ('acik', 'inceleniyor', 'cevaplandi', 'kapali'))
);

CREATE INDEX IF NOT EXISTS idx_destek_talepleri_firma ON public.destek_talepleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_destek_talepleri_durum ON public.destek_talepleri(durum);
CREATE INDEX IF NOT EXISTS idx_destek_talepleri_user ON public.destek_talepleri(user_id);

-- ---------------------------------------------------------
-- 2. PLATFORM LOGLARİ TABLOSU (Admin İşlem Kaydı)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.platform_loglari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    islem_tipi TEXT NOT NULL,
    hedef_tablo TEXT,
    hedef_id TEXT,
    detay JSONB DEFAULT '{}'::jsonb,
    ip_adresi TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_platform_loglari_admin ON public.platform_loglari(admin_id);
CREATE INDEX IF NOT EXISTS idx_platform_loglari_tarih ON public.platform_loglari(created_at DESC);

-- ---------------------------------------------------------
-- 3. PLATFORM DUYURULARI TABLOSU
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.platform_duyurulari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    baslik TEXT NOT NULL,
    icerik TEXT NOT NULL,
    tur TEXT NOT NULL DEFAULT 'bilgi',
    hedef TEXT NOT NULL DEFAULT 'tumu',
    aktif BOOLEAN DEFAULT true,
    baslangic_tarihi TIMESTAMPTZ DEFAULT now(),
    bitis_tarihi TIMESTAMPTZ,
    olusturan_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT chk_duyuru_tur CHECK (tur IN ('bilgi', 'uyari', 'bakim', 'guncelleme')),
    CONSTRAINT chk_duyuru_hedef CHECK (hedef IN ('tumu', 'admin', 'deneme', 'pro', 'enterprise'))
);

-- ---------------------------------------------------------
-- 4. PLATFORM İSTATİSTİK VIEW'LARI
-- ---------------------------------------------------------

-- Firma istatistikleri özet view
CREATE OR REPLACE VIEW public.v_platform_firma_ozet AS
SELECT
    f.id AS firma_id,
    f.firma_adi,
    f.firma_kodu,
    f.aktif,
    f.created_at AS kayit_tarihi,
    (SELECT COUNT(*) FROM firma_kullanicilari fk WHERE fk.firma_id = f.id AND fk.aktif = true) AS kullanici_sayisi,
    (SELECT COUNT(*) FROM firma_modulleri fm WHERE fm.firma_id = f.id AND fm.aktif = true) AS modul_sayisi,
    fa.durum AS abonelik_durumu,
    ap.plan_adi,
    ap.plan_kodu,
    ap.aylik_ucret,
    fa.deneme_bitis
FROM firmalar f
LEFT JOIN LATERAL (
    SELECT fa2.durum, fa2.plan_id, fa2.deneme_bitis
    FROM firma_abonelikleri fa2
    WHERE fa2.firma_id = f.id
    ORDER BY fa2.created_at DESC
    LIMIT 1
) fa ON true
LEFT JOIN abonelik_planlari ap ON ap.id = fa.plan_id;

-- Platform genel istatistikleri view
CREATE OR REPLACE VIEW public.v_platform_istatistikleri AS
SELECT
    (SELECT COUNT(*) FROM firmalar WHERE aktif = true) AS aktif_firma_sayisi,
    (SELECT COUNT(*) FROM firmalar WHERE aktif = false) AS pasif_firma_sayisi,
    (SELECT COUNT(*) FROM firmalar) AS toplam_firma_sayisi,
    (SELECT COUNT(DISTINCT user_id) FROM firma_kullanicilari WHERE aktif = true) AS toplam_kullanici_sayisi,
    (SELECT COUNT(*) FROM firma_abonelikleri WHERE durum = 'aktif') AS aktif_abonelik_sayisi,
    (SELECT COUNT(*) FROM firma_abonelikleri WHERE durum = 'deneme') AS deneme_abonelik_sayisi,
    (SELECT COALESCE(SUM(ap.aylik_ucret), 0) FROM firma_abonelikleri fa JOIN abonelik_planlari ap ON ap.id = fa.plan_id WHERE fa.durum = 'aktif') AS aylik_gelir,
    (SELECT COUNT(*) FROM destek_talepleri WHERE durum IN ('acik', 'inceleniyor')) AS acik_destek_sayisi;

DO $$ BEGIN RAISE NOTICE 'Asama 9 tamamlandi: Platform admin tablolari ve view''lar olusturuldu.'; END $$;
