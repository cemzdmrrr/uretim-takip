-- ============================================================
-- AŞAMA 1.1: MULTI-TENANT TEMEL TABLOLAR
-- TexPilot SaaS Dönüşümü - Firma ve Modül Altyapısı
-- ============================================================
-- Bu script yeni bir Supabase projesinde veya mevcut projede çalıştırılır.
-- Mevcut veriler korunur, sadece yeni tablolar oluşturulur.
-- ============================================================

-- ─────────────────────────────────────────────────────────
-- 1. ANA FİRMA (TENANT) TABLOSU
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firmalar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_adi VARCHAR(255) NOT NULL,
    firma_kodu VARCHAR(50) UNIQUE NOT NULL,
    vergi_no VARCHAR(20),
    vergi_dairesi VARCHAR(100),
    sicil_no VARCHAR(50),
    sgk_sicil_no VARCHAR(50),
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(255),
    web VARCHAR(255),
    logo_url TEXT,
    yetkili VARCHAR(255),
    iban VARCHAR(50),
    banka VARCHAR(100),
    sektor VARCHAR(100) DEFAULT 'tekstil',
    faaliyet VARCHAR(255),
    kurulus_yili INT,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Firma kodu için unique index (arama ve URL slug)
CREATE INDEX IF NOT EXISTS idx_firmalar_firma_kodu ON firmalar(firma_kodu);
CREATE INDEX IF NOT EXISTS idx_firmalar_aktif ON firmalar(aktif);

-- ─────────────────────────────────────────────────────────
-- 2. FİRMA AYARLARI (KEY-VALUE, FİRMA BAZLI)
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firma_ayarlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    anahtar VARCHAR(255) NOT NULL,
    deger TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(firma_id, anahtar)
);

CREATE INDEX IF NOT EXISTS idx_firma_ayarlari_firma ON firma_ayarlari(firma_id);

-- ─────────────────────────────────────────────────────────
-- 3. KULLANICI-FİRMA İLİŞKİ TABLOSU (yeniden yapılandırma)
-- ─────────────────────────────────────────────────────────
-- Mevcut firma_kullanicilari tablosu varsa düşür
-- NOT: Eğer mevcut tablo kullanımdaysa önce yedek alın
DROP TABLE IF EXISTS firma_kullanicilari CASCADE;

CREATE TABLE firma_kullanicilari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rol VARCHAR(50) NOT NULL DEFAULT 'kullanici',
    -- roller: firma_sahibi, firma_admin, yonetici, kullanici, personel,
    --         dokumaci, konfeksiyoncu, kalite_kontrol, sofor, muhasebeci, depocu
    yetki_grubu JSONB DEFAULT '[]'::jsonb,
    aktif BOOLEAN DEFAULT true,
    davet_tarihi TIMESTAMPTZ DEFAULT NOW(),
    katilim_tarihi TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(firma_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_firma ON firma_kullanicilari(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_user ON firma_kullanicilari(user_id);
CREATE INDEX IF NOT EXISTS idx_firma_kullanicilari_aktif ON firma_kullanicilari(firma_id, aktif);

-- ─────────────────────────────────────────────────────────
-- 4. KULLANICI AKTİF FİRMA SEÇİMİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kullanici_aktif_firma (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    son_giris TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kullanici_aktif_firma_firma ON kullanici_aktif_firma(firma_id);

-- ─────────────────────────────────────────────────────────
-- 5. FİRMA DAVET SİSTEMİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firma_davetleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    davet_eden_id UUID NOT NULL REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL,
    rol VARCHAR(50) DEFAULT 'kullanici',
    davet_kodu VARCHAR(20) UNIQUE NOT NULL,
    durum VARCHAR(20) DEFAULT 'beklemede',
    -- beklemede, kabul_edildi, suresi_doldu, iptal
    created_at TIMESTAMPTZ DEFAULT NOW(),
    gecerlilik_tarihi TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);

CREATE INDEX IF NOT EXISTS idx_firma_davetleri_kod ON firma_davetleri(davet_kodu);
CREATE INDEX IF NOT EXISTS idx_firma_davetleri_email ON firma_davetleri(email);
CREATE INDEX IF NOT EXISTS idx_firma_davetleri_firma ON firma_davetleri(firma_id);

-- ─────────────────────────────────────────────────────────
-- 6. MODÜL TANIMLARI (Platform tarafından yönetilir)
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modul_tanimlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modul_kodu VARCHAR(50) UNIQUE NOT NULL,
    modul_adi VARCHAR(255) NOT NULL,
    aciklama TEXT,
    kategori VARCHAR(100) NOT NULL,
    -- kategoriler: uretim, finans, ik, stok, sevkiyat, tedarik, crm, rapor, sistem
    ikon VARCHAR(100),
    sira_no INT DEFAULT 0,
    bagimliliklar JSONB DEFAULT '[]'::jsonb,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 7. ÜRETİM ALT-MODÜLLERİ (Tekstil Dalları)
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS uretim_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modul_kodu VARCHAR(50) UNIQUE NOT NULL,
    modul_adi VARCHAR(255) NOT NULL,
    tekstil_dali VARCHAR(100) NOT NULL,
    aciklama TEXT,
    uretim_asamalari JSONB NOT NULL DEFAULT '[]'::jsonb,
    varsayilan_asamalar JSONB NOT NULL DEFAULT '[]'::jsonb,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 8. FİRMA-MODÜL İLİŞKİSİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firma_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    modul_id UUID NOT NULL REFERENCES modul_tanimlari(id),
    aktif BOOLEAN DEFAULT true,
    aktivasyon_tarihi TIMESTAMPTZ DEFAULT NOW(),
    bitis_tarihi TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(firma_id, modul_id)
);

CREATE INDEX IF NOT EXISTS idx_firma_modulleri_firma ON firma_modulleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_modulleri_aktif ON firma_modulleri(firma_id, aktif);

-- ─────────────────────────────────────────────────────────
-- 9. FİRMA-ÜRETİM MODÜLÜ İLİŞKİSİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firma_uretim_modulleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    uretim_modul_id UUID NOT NULL REFERENCES uretim_modulleri(id),
    aktif BOOLEAN DEFAULT true,
    ozel_asamalar JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(firma_id, uretim_modul_id)
);

CREATE INDEX IF NOT EXISTS idx_firma_uretim_mod_firma ON firma_uretim_modulleri(firma_id);

-- ─────────────────────────────────────────────────────────
-- 10. ABONELİK PLANLARI
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS abonelik_planlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_kodu VARCHAR(50) UNIQUE NOT NULL,
    plan_adi VARCHAR(255) NOT NULL,
    aciklama TEXT,
    aylik_ucret DECIMAL(10,2) NOT NULL DEFAULT 0,
    yillik_ucret DECIMAL(10,2),
    max_kullanici INT,
    max_modul INT,
    dahil_moduller JSONB DEFAULT '[]'::jsonb,
    ozellikler JSONB DEFAULT '{}'::jsonb,
    aktif BOOLEAN DEFAULT true,
    sira_no INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- 11. FİRMA ABONELİKLERİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS firma_abonelikleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES abonelik_planlari(id),
    durum VARCHAR(20) DEFAULT 'deneme',
    -- aktif, pasif, deneme, iptal, odeme_bekleniyor
    baslangic_tarihi TIMESTAMPTZ DEFAULT NOW(),
    bitis_tarihi TIMESTAMPTZ,
    deneme_bitis TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
    odeme_periyodu VARCHAR(20) DEFAULT 'aylik',
    son_odeme_tarihi TIMESTAMPTZ,
    sonraki_odeme_tarihi TIMESTAMPTZ,
    iptal_tarihi TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_firma_abonelikleri_firma ON firma_abonelikleri(firma_id);
CREATE INDEX IF NOT EXISTS idx_firma_abonelikleri_durum ON firma_abonelikleri(durum);

-- ─────────────────────────────────────────────────────────
-- 12. ABONELİK ÖDEMELERİ
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS abonelik_odemeleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id),
    abonelik_id UUID NOT NULL REFERENCES firma_abonelikleri(id),
    tutar DECIMAL(10,2) NOT NULL,
    para_birimi VARCHAR(3) DEFAULT 'TRY',
    odeme_tarihi TIMESTAMPTZ DEFAULT NOW(),
    odeme_yontemi VARCHAR(50),
    odeme_referans VARCHAR(255),
    durum VARCHAR(20) DEFAULT 'basarili',
    -- basarili, basarisiz, beklemede, iade
    fatura_no VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_abonelik_odemeleri_firma ON abonelik_odemeleri(firma_id);

-- ─────────────────────────────────────────────────────────
-- 13. YETKİ TANIMLARI (Modül-Rol bazlı)
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS yetki_tanimlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID REFERENCES firmalar(id) ON DELETE CASCADE,
    -- firma_id NULL ise platform varsayılanı
    rol VARCHAR(50) NOT NULL,
    modul_kodu VARCHAR(50) NOT NULL,
    yetki VARCHAR(50) NOT NULL,
    -- okuma, yazma, silme, yonetim, export
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(firma_id, rol, modul_kodu, yetki)
);

CREATE INDEX IF NOT EXISTS idx_yetki_tanimlari_firma ON yetki_tanimlari(firma_id);
CREATE INDEX IF NOT EXISTS idx_yetki_tanimlari_rol ON yetki_tanimlari(rol, modul_kodu);

-- ============================================================
-- VARSAYILAN VERİLER: MODÜL TANIMLARI
-- ============================================================

INSERT INTO modul_tanimlari (modul_kodu, modul_adi, aciklama, kategori, ikon, sira_no, bagimliliklar)
VALUES
    ('uretim', 'Üretim Yönetimi', 'Ana üretim takip modülü - en az 1 üretim dalı seçilmeli', 'uretim', 'factory', 1, '[]'),
    ('finans', 'Finans & Muhasebe', 'Fatura, kasa-banka, ödeme yönetimi', 'finans', 'account_balance', 2, '[]'),
    ('ik', 'İnsan Kaynakları', 'Personel, maaş, puantaj, izin, mesai yönetimi', 'ik', 'people', 3, '[]'),
    ('stok', 'Stok & Depo', 'Hammadde, aksesuar, ürün depo yönetimi', 'stok', 'inventory', 4, '[]'),
    ('sevkiyat', 'Sevkiyat & Lojistik', 'Sevkiyat planlama, takip, şoför paneli', 'sevkiyat', 'local_shipping', 5, '["uretim"]'),
    ('tedarik', 'Tedarikçi Yönetimi', 'Tedarikçi tanım, sipariş, ödeme takibi', 'tedarik', 'handshake', 6, '[]'),
    ('musteri', 'Müşteri Yönetimi', 'Müşteri tanım, sipariş takip, CRM', 'crm', 'storefront', 7, '[]'),
    ('rapor', 'Raporlar & Analiz', 'Gelişmiş raporlama, KPI, dışa aktarma', 'rapor', 'analytics', 8, '[]'),
    ('kalite', 'Kalite Kontrol', 'Kalite kontrol süreçleri ve raporlama', 'uretim', 'verified', 9, '["uretim"]'),
    ('ayarlar', 'Sistem Ayarları', 'Firma ayarları, kullanıcı yönetimi, modül yönetimi', 'sistem', 'settings', 10, '[]')
ON CONFLICT (modul_kodu) DO NOTHING;

-- ============================================================
-- VARSAYILAN VERİLER: ÜRETİM DALLARI
-- ============================================================

INSERT INTO uretim_modulleri (modul_kodu, modul_adi, tekstil_dali, aciklama, uretim_asamalari, varsayilan_asamalar)
VALUES
    ('triko', 'Triko Üretim', 'triko',
     'Triko (örme) üretim takibi - düz örme, jakar, intarsia vb.',
     '[
        {"kod": "tasarim", "ad": "Tasarım", "sira": 1, "zorunlu": false},
        {"kod": "dokuma", "ad": "Dokuma/Örme", "sira": 2, "zorunlu": true},
        {"kod": "yikama", "ad": "Yıkama", "sira": 3, "zorunlu": false},
        {"kod": "nakis", "ad": "Nakış", "sira": 4, "zorunlu": false},
        {"kod": "ilik_dugme", "ad": "İlik Düğme", "sira": 5, "zorunlu": false},
        {"kod": "konfeksiyon", "ad": "Konfeksiyon", "sira": 6, "zorunlu": true},
        {"kod": "utu", "ad": "Ütü", "sira": 7, "zorunlu": true},
        {"kod": "paketleme", "ad": "Paketleme", "sira": 8, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 9, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 10, "zorunlu": true}
     ]'::jsonb,
     '["dokuma","konfeksiyon","utu","paketleme","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('dokuma_kumas', 'Dokuma Kumaş', 'dokuma_kumas',
     'Dokuma kumaş üretim takibi - şifon, poplin, gabardin vb.',
     '[
        {"kod": "cozgu_hazirlama", "ad": "Çözgü Hazırlama", "sira": 1, "zorunlu": true},
        {"kod": "dokuma", "ad": "Dokuma", "sira": 2, "zorunlu": true},
        {"kod": "hasil", "ad": "Haşıl", "sira": 3, "zorunlu": false},
        {"kod": "terbiye", "ad": "Terbiye/Apre", "sira": 4, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 5, "zorunlu": true},
        {"kod": "depolama", "ad": "Depolama", "sira": 6, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 7, "zorunlu": true}
     ]'::jsonb,
     '["cozgu_hazirlama","dokuma","terbiye","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('konfeksiyon', 'Konfeksiyon (Hazır Giyim)', 'konfeksiyon',
     'Hazır giyim üretim takibi - kesim, dikim, paketleme',
     '[
        {"kod": "tasarim", "ad": "Tasarım/Kalıp", "sira": 1, "zorunlu": false},
        {"kod": "kesim", "ad": "Kesim", "sira": 2, "zorunlu": true},
        {"kod": "dikim", "ad": "Dikim", "sira": 3, "zorunlu": true},
        {"kod": "utu_pres", "ad": "Ütü/Pres", "sira": 4, "zorunlu": true},
        {"kod": "aksesuar", "ad": "Aksesuar Takma", "sira": 5, "zorunlu": false},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 6, "zorunlu": true},
        {"kod": "paketleme", "ad": "Paketleme", "sira": 7, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 8, "zorunlu": true}
     ]'::jsonb,
     '["kesim","dikim","utu_pres","kalite_kontrol","paketleme","sevkiyat"]'::jsonb
    ),
    ('orme_kumas', 'Örme Kumaş', 'orme_kumas',
     'Örme kumaş üretim takibi - süprem, ribana, interlok vb.',
     '[
        {"kod": "iplik_hazirlama", "ad": "İplik Hazırlama", "sira": 1, "zorunlu": true},
        {"kod": "orme", "ad": "Örme", "sira": 2, "zorunlu": true},
        {"kod": "boyama", "ad": "Boyama", "sira": 3, "zorunlu": true},
        {"kod": "terbiye", "ad": "Terbiye/Apre", "sira": 4, "zorunlu": false},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 5, "zorunlu": true},
        {"kod": "depolama", "ad": "Depolama", "sira": 6, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 7, "zorunlu": true}
     ]'::jsonb,
     '["iplik_hazirlama","orme","boyama","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('boya_terbiye', 'Boya & Terbiye', 'boya_terbiye',
     'Boya ve terbiye hizmetleri takibi',
     '[
        {"kod": "malzeme_kabul", "ad": "Malzeme Kabul", "sira": 1, "zorunlu": true},
        {"kod": "on_terbiye", "ad": "Ön Terbiye", "sira": 2, "zorunlu": false},
        {"kod": "boyama", "ad": "Boyama", "sira": 3, "zorunlu": true},
        {"kod": "baski", "ad": "Baskı", "sira": 4, "zorunlu": false},
        {"kod": "son_terbiye", "ad": "Son Terbiye/Apre", "sira": 5, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 6, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 7, "zorunlu": true}
     ]'::jsonb,
     '["malzeme_kabul","boyama","son_terbiye","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('baski_desen', 'Baskı & Desen', 'baski_desen',
     'Tekstil baskı ve desen uygulama takibi',
     '[
        {"kod": "tasarim", "ad": "Tasarım/Desen", "sira": 1, "zorunlu": true},
        {"kod": "kalip_sablon", "ad": "Kalıp/Şablon", "sira": 2, "zorunlu": true},
        {"kod": "baski", "ad": "Baskı", "sira": 3, "zorunlu": true},
        {"kod": "kurutma", "ad": "Kurutma", "sira": 4, "zorunlu": true},
        {"kod": "fiksaj", "ad": "Fiksaj", "sira": 5, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 6, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 7, "zorunlu": true}
     ]'::jsonb,
     '["tasarim","baski","kurutma","fiksaj","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('iplik_uretim', 'İplik Üretim', 'iplik_uretim',
     'İplik üretim süreçleri takibi',
     '[
        {"kod": "hammadde_kabul", "ad": "Hammadde Kabul", "sira": 1, "zorunlu": true},
        {"kod": "harman", "ad": "Harman/Hallaç", "sira": 2, "zorunlu": true},
        {"kod": "tarak", "ad": "Tarak", "sira": 3, "zorunlu": true},
        {"kod": "fitil", "ad": "Fitil", "sira": 4, "zorunlu": true},
        {"kod": "bukum", "ad": "Büküm/Eğirme", "sira": 5, "zorunlu": true},
        {"kod": "bobin", "ad": "Bobinleme", "sira": 6, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 7, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 8, "zorunlu": true}
     ]'::jsonb,
     '["hammadde_kabul","harman","tarak","bukum","bobin","kalite_kontrol","sevkiyat"]'::jsonb
    ),
    ('teknik_tekstil', 'Teknik Tekstil', 'teknik_tekstil',
     'Teknik tekstil üretim takibi - nonwoven, kompozit, kaplama vb.',
     '[
        {"kod": "malzeme_secim", "ad": "Malzeme Seçim", "sira": 1, "zorunlu": true},
        {"kod": "uretim", "ad": "Üretim", "sira": 2, "zorunlu": true},
        {"kod": "kaplama", "ad": "Kaplama/Laminasyon", "sira": 3, "zorunlu": false},
        {"kod": "test", "ad": "Test & Analiz", "sira": 4, "zorunlu": true},
        {"kod": "kalite_kontrol", "ad": "Kalite Kontrol", "sira": 5, "zorunlu": true},
        {"kod": "sevkiyat", "ad": "Sevkiyat", "sira": 6, "zorunlu": true}
     ]'::jsonb,
     '["malzeme_secim","uretim","test","kalite_kontrol","sevkiyat"]'::jsonb
    )
ON CONFLICT (modul_kodu) DO NOTHING;

-- ============================================================
-- VARSAYILAN VERİLER: ABONELİK PLANLARI
-- ============================================================

INSERT INTO abonelik_planlari (plan_kodu, plan_adi, aciklama, aylik_ucret, yillik_ucret, max_kullanici, max_modul, dahil_moduller, ozellikler, sira_no)
VALUES
    ('deneme', 'Deneme', '14 günlük ücretsiz deneme — tüm modüller dahil', 0, 0, 5, NULL,
     '["uretim","finans","ik","stok","sevkiyat","tedarik","musteri","rapor","kalite","ayarlar"]'::jsonb,
     '{"deneme_suresi_gun": 14, "destek": "email", "tum_moduller": true}'::jsonb, 0),
    ('baslangic', 'Başlangıç', 'Küçük atölyeler için temel paket', 499, 4990, 3, 3,
     '["uretim","ayarlar"]'::jsonb,
     '{"max_uretim_dali": 1, "destek": "email", "export": false}'::jsonb, 1),
    ('profesyonel', 'Profesyonel', 'Orta ölçekli firmalar için gelişmiş paket', 999, 9990, 10, 6,
     '["uretim","finans","stok","rapor","ayarlar"]'::jsonb,
     '{"max_uretim_dali": 3, "destek": "email_telefon", "export": true}'::jsonb, 2),
    ('kurumsal', 'Kurumsal', 'Büyük firmalar için tam paket', 1999, 19990, 25, NULL,
     '["uretim","finans","ik","stok","sevkiyat","tedarik","musteri","rapor","kalite","ayarlar"]'::jsonb,
     '{"max_uretim_dali": null, "destek": "oncelikli", "export": true, "api_erisim": true}'::jsonb, 3),
    ('enterprise', 'Enterprise', 'Özel çözüm, sınırsız kapasite', 0, 0, NULL, NULL,
     '["uretim","finans","ik","stok","sevkiyat","tedarik","musteri","rapor","kalite","ayarlar"]'::jsonb,
     '{"max_uretim_dali": null, "destek": "ozel", "export": true, "api_erisim": true, "ozel_gelistirme": true}'::jsonb, 4)
ON CONFLICT (plan_kodu) DO NOTHING;

-- ============================================================
-- VARSAYILAN VERİLER: PLATFORM VARSAYILAN YETKİLER
-- ============================================================

-- firma_sahibi ve firma_admin: tüm modüllerde tam yetki
INSERT INTO yetki_tanimlari (firma_id, rol, modul_kodu, yetki)
SELECT NULL, rol, modul.modul_kodu, yetki
FROM (VALUES ('firma_sahibi'), ('firma_admin')) AS r(rol)
CROSS JOIN modul_tanimlari modul
CROSS JOIN (VALUES ('okuma'), ('yazma'), ('silme'), ('yonetim'), ('export')) AS y(yetki)
ON CONFLICT DO NOTHING;

-- yonetici: okuma, yazma, export (silme ve yönetim hariç)
INSERT INTO yetki_tanimlari (firma_id, rol, modul_kodu, yetki)
SELECT NULL, 'yonetici', modul.modul_kodu, yetki
FROM modul_tanimlari modul
CROSS JOIN (VALUES ('okuma'), ('yazma'), ('export')) AS y(yetki)
ON CONFLICT DO NOTHING;

-- kullanici: okuma, yazma (silme, yönetim, export hariç)
INSERT INTO yetki_tanimlari (firma_id, rol, modul_kodu, yetki)
SELECT NULL, 'kullanici', modul.modul_kodu, yetki
FROM modul_tanimlari modul
CROSS JOIN (VALUES ('okuma'), ('yazma')) AS y(yetki)
WHERE modul.modul_kodu != 'ayarlar'
ON CONFLICT DO NOTHING;

-- personel: sadece kendi modüllerinde okuma
INSERT INTO yetki_tanimlari (firma_id, rol, modul_kodu, yetki)
SELECT NULL, 'personel', modul_kodu, 'okuma'
FROM modul_tanimlari
WHERE modul_kodu IN ('ik')
ON CONFLICT DO NOTHING;

-- ============================================================
-- HELPER FONKSİYONLAR
-- ============================================================

-- Kullanıcının erişebildiği firma ID'lerini döndürür
CREATE OR REPLACE FUNCTION get_user_firma_ids()
RETURNS SETOF UUID AS $$
    SELECT firma_id FROM firma_kullanicilari
    WHERE user_id = auth.uid() AND aktif = true;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Kullanıcının aktif firma ID'sini döndürür
CREATE OR REPLACE FUNCTION get_active_firma_id()
RETURNS UUID AS $$
    SELECT firma_id FROM kullanici_aktif_firma
    WHERE user_id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Kullanıcının belirli firmadaki rolünü döndürür
CREATE OR REPLACE FUNCTION get_user_firma_rol(p_firma_id UUID)
RETURNS VARCHAR AS $$
    SELECT rol FROM firma_kullanicilari
    WHERE user_id = auth.uid()
    AND firma_id = p_firma_id
    AND aktif = true
    LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Kullanıcının aktif firmadaki rolünü döndürür
CREATE OR REPLACE FUNCTION get_active_firma_rol()
RETURNS VARCHAR AS $$
    SELECT fk.rol FROM firma_kullanicilari fk
    INNER JOIN kullanici_aktif_firma kaf ON kaf.firma_id = fk.firma_id AND kaf.user_id = fk.user_id
    WHERE fk.user_id = auth.uid()
    AND fk.aktif = true
    LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Kullanıcının platform admin olup olmadığını kontrol eder
CREATE OR REPLACE FUNCTION is_platform_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS(
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
        AND role = 'admin'
        AND aktif = true
    );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Updated_at otomatik güncelleme trigger fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- firmalar tablosuna updated_at trigger ekle
DROP TRIGGER IF EXISTS trg_firmalar_updated_at ON firmalar;
CREATE TRIGGER trg_firmalar_updated_at
    BEFORE UPDATE ON firmalar
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- firma_kullanicilari tablosuna updated_at trigger ekle
DROP TRIGGER IF EXISTS trg_firma_kullanicilari_updated_at ON firma_kullanicilari;
CREATE TRIGGER trg_firma_kullanicilari_updated_at
    BEFORE UPDATE ON firma_kullanicilari
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- firma_abonelikleri tablosuna updated_at trigger ekle
DROP TRIGGER IF EXISTS trg_firma_abonelikleri_updated_at ON firma_abonelikleri;
CREATE TRIGGER trg_firma_abonelikleri_updated_at
    BEFORE UPDATE ON firma_abonelikleri
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DO $$ BEGIN RAISE NOTICE '✅ Aşama 1.1 tamamlandı: Multi-tenant temel tablolar ve varsayılan veriler oluşturuldu.'; END $$;
