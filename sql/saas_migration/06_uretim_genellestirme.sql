-- ============================================================
-- ASAMA 8: URETIM MODULU GENELLESTIRME
-- TexPilot SaaS Donusumu - Genel Uretim Altyapisi
-- ============================================================
-- Bu script triko'ya ozgu yapiyi genel tekstil uretimine donusturur.
-- Mevcut atama tablolari korunur, genel tablo eklenir.
-- ============================================================

-- ---------------------------------------------------------
-- 1. GENEL URETIM ATAMALARI TABLOSU
-- Tum uretim asamalari icin tek tablo
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS uretim_atamalari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firma_id UUID NOT NULL REFERENCES firmalar(id) ON DELETE CASCADE,
    model_id INT REFERENCES modeller(id),
    siparis_id INT, -- opsiyonel siparis referansi
    uretim_dali VARCHAR(50) NOT NULL, -- triko, konfeksiyon, dokuma_kumas vb.
    asama_kodu VARCHAR(50) NOT NULL, -- dokuma, kesim, dikim, boyama vb.
    asama_sira_no INT NOT NULL DEFAULT 0,
    atanan_email VARCHAR(255),
    atanan_kullanici_id UUID REFERENCES auth.users(id),
    atanan_tedarikci_id UUID,
    toplam_adet INT DEFAULT 0,
    tamamlanan_adet INT DEFAULT 0,
    fire_adet INT DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'atandi'
        CHECK (durum IN ('atandi','basladi','devam_ediyor','tamamlandi','iptal','beklemede')),
    baslama_tarihi TIMESTAMPTZ,
    bitis_tarihi TIMESTAMPTZ,
    hedef_bitis TIMESTAMPTZ,
    notlar TEXT,
    ozel_alanlar JSONB DEFAULT '{}'::jsonb, -- asamaya ozgu ek veriler
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indeksler
CREATE INDEX IF NOT EXISTS idx_uretim_atamalari_firma ON uretim_atamalari(firma_id);
CREATE INDEX IF NOT EXISTS idx_uretim_atamalari_model ON uretim_atamalari(model_id);
CREATE INDEX IF NOT EXISTS idx_uretim_atamalari_dal_asama ON uretim_atamalari(uretim_dali, asama_kodu);
CREATE INDEX IF NOT EXISTS idx_uretim_atamalari_durum ON uretim_atamalari(durum);
CREATE INDEX IF NOT EXISTS idx_uretim_atamalari_atanan ON uretim_atamalari(atanan_email);

-- RLS
ALTER TABLE uretim_atamalari ENABLE ROW LEVEL SECURITY;

CREATE POLICY "uretim_atamalari_firma_izolasyon" ON uretim_atamalari
    FOR ALL USING (
        firma_id IN (
            SELECT fk.firma_id FROM firma_kullanicilari fk
            WHERE fk.user_id = auth.uid() AND fk.aktif = true
        )
    );

-- ---------------------------------------------------------
-- 2. DAL FORM ALANLARI TABLOSU
-- Tekstil dalina ozgu dinamik form alanlari
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS dal_form_alanlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tekstil_dali VARCHAR(50) NOT NULL,
    alan_kodu VARCHAR(100) NOT NULL,
    alan_adi VARCHAR(200) NOT NULL,
    alan_tipi VARCHAR(30) NOT NULL DEFAULT 'text'
        CHECK (alan_tipi IN ('text','number','dropdown','checkbox','date','textarea','color')),
    secenekler JSONB, -- dropdown icin secenek listesi
    varsayilan_deger TEXT,
    zorunlu BOOLEAN DEFAULT false,
    sira_no INT DEFAULT 0,
    aktif BOOLEAN DEFAULT true,
    grup VARCHAR(100), -- form icinde gruplama
    UNIQUE(tekstil_dali, alan_kodu)
);

CREATE INDEX IF NOT EXISTS idx_dal_form_alanlari_dal ON dal_form_alanlari(tekstil_dali);

-- ---------------------------------------------------------
-- 3. ASAMA TANIM TABLOSU (DB-driven stage registry)
-- Her dal icin asamalar ve maplemeler
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS asama_tanimlari (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tekstil_dali VARCHAR(50) NOT NULL,
    asama_kodu VARCHAR(50) NOT NULL,
    asama_adi VARCHAR(100) NOT NULL,
    sira_no INT NOT NULL DEFAULT 0,
    zorunlu BOOLEAN DEFAULT false,
    ikon VARCHAR(50), -- Material icon adi
    renk VARCHAR(10), -- hex renk kodu
    eski_tablo_adi VARCHAR(100), -- geriye uyumluluk icin eski atama tablosu
    eski_durum_kolonu VARCHAR(100), -- geriye uyumluluk: triko_takip'teki durum kolonu
    aktif BOOLEAN DEFAULT true,
    UNIQUE(tekstil_dali, asama_kodu)
);

CREATE INDEX IF NOT EXISTS idx_asama_tanimlari_dal ON asama_tanimlari(tekstil_dali);

-- ---------------------------------------------------------
-- 4. MODELLER TABLOSUNA GENEL ALANLAR EKLEME
-- ---------------------------------------------------------

-- uretim_dali kolonu ekle (mevcut tablo triko icindi)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='modeller' AND column_name='uretim_dali'
    ) THEN
        ALTER TABLE modeller ADD COLUMN uretim_dali VARCHAR(50) DEFAULT 'triko';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='modeller' AND column_name='urun_tipi'
    ) THEN
        ALTER TABLE modeller ADD COLUMN urun_tipi VARCHAR(100);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='modeller' AND column_name='dal_ozel_alanlar'
    ) THEN
        ALTER TABLE modeller ADD COLUMN dal_ozel_alanlar JSONB DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- ---------------------------------------------------------
-- 5. SEED DATA: TRIKO ASAMALARI (mevcut sisteme uyumlu)
-- ---------------------------------------------------------

INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk, eski_tablo_adi, eski_durum_kolonu) VALUES
    ('triko', 'dokuma',          'Dokuma/Örme',      1, true,  'design_services',        '1976D2', 'dokuma_atamalari',          'orgu_durumu'),
    ('triko', 'yikama',          'Yıkama',           2, false, 'local_laundry_service',  '00838F', 'yikama_atamalari',          'yikama_durumu'),
    ('triko', 'nakis',           'Nakış',            3, false, 'brush',                  'FF6F00', 'nakis_atamalari',           'nakis_durumu'),
    ('triko', 'ilik_dugme',      'İlik Düğme',       4, false, 'radio_button_checked',   '7B1FA2', 'ilik_dugme_atamalari',      'ilik_dugme_durumu'),
    ('triko', 'konfeksiyon',     'Konfeksiyon',      5, true,  'checkroom',              'E65100', 'konfeksiyon_atamalari',     'konfeksiyon_durumu'),
    ('triko', 'utu',             'Ütü',              6, true,  'iron',                   'AD1457', 'utu_atamalari',             'utu_durumu'),
    ('triko', 'paketleme',       'Paketleme',        7, true,  'inventory_2',            '4E342E', 'paketleme_atamalari',       'paketleme_durumu'),
    ('triko', 'kalite_kontrol',  'Kalite Kontrol',   8, true,  'verified',               '2E7D32', 'kalite_kontrol_atamalari',  'kalite_durumu'),
    ('triko', 'sevkiyat',        'Sevkiyat',         9, true,  'local_shipping',         '1565C0', NULL,                        NULL)
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Konfeksiyon asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('konfeksiyon', 'tasarim',      'Tasarım',         1, false, 'palette',               '7B1FA2'),
    ('konfeksiyon', 'kalip',        'Kalıp',           2, true,  'straighten',            '00695C'),
    ('konfeksiyon', 'kesim',        'Kesim',           3, true,  'content_cut',           'E65100'),
    ('konfeksiyon', 'dikim',        'Dikim',           4, true,  'checkroom',             '1565C0'),
    ('konfeksiyon', 'utu_pres',     'Ütü/Pres',       5, true,  'iron',                  'AD1457'),
    ('konfeksiyon', 'aksesuar',     'Aksesuar',        6, false, 'style',                 'FF6F00'),
    ('konfeksiyon', 'kalite',       'Kalite',          7, true,  'verified',              '2E7D32'),
    ('konfeksiyon', 'paketleme',    'Paketleme',       8, true,  'inventory_2',           '4E342E'),
    ('konfeksiyon', 'sevkiyat',     'Sevkiyat',        9, true,  'local_shipping',        '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Dokuma kumas asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('dokuma_kumas', 'cozgu',       'Çözgü Hazırlama', 1, true,  'linear_scale',         '6D4C41'),
    ('dokuma_kumas', 'dokuma',      'Dokuma',           2, true,  'design_services',       '1976D2'),
    ('dokuma_kumas', 'hasil',       'Haşıl',           3, false, 'water_drop',            '00838F'),
    ('dokuma_kumas', 'terbiye',     'Terbiye',         4, false, 'science',               '7B1FA2'),
    ('dokuma_kumas', 'kalite',      'Kalite',          5, true,  'verified',              '2E7D32'),
    ('dokuma_kumas', 'depolama',    'Depolama',        6, true,  'warehouse',             '4E342E'),
    ('dokuma_kumas', 'sevkiyat',    'Sevkiyat',        7, true,  'local_shipping',        '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Orme kumas asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('orme_kumas', 'iplik_hazirlama', 'İplik Hazırlama', 1, true,  'linear_scale',      '6D4C41'),
    ('orme_kumas', 'orme',            'Örme',            2, true,  'design_services',    '1976D2'),
    ('orme_kumas', 'boyama',          'Boyama',          3, false, 'color_lens',         '7B1FA2'),
    ('orme_kumas', 'terbiye',         'Terbiye',         4, false, 'science',            '00838F'),
    ('orme_kumas', 'kalite',          'Kalite',          5, true,  'verified',           '2E7D32'),
    ('orme_kumas', 'depolama',        'Depolama',        6, true,  'warehouse',          '4E342E'),
    ('orme_kumas', 'sevkiyat',        'Sevkiyat',        7, true,  'local_shipping',     '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Boya terbiye asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('boya_terbiye', 'malzeme_kabul', 'Malzeme Kabul',  1, true,  'inventory',          '6D4C41'),
    ('boya_terbiye', 'on_terbiye',    'Ön Terbiye',     2, true,  'science',            '00838F'),
    ('boya_terbiye', 'boyama',        'Boyama',         3, true,  'color_lens',         '7B1FA2'),
    ('boya_terbiye', 'baski',         'Baskı',          4, false, 'print',              'E65100'),
    ('boya_terbiye', 'son_terbiye',   'Son Terbiye',    5, true,  'science',            '1565C0'),
    ('boya_terbiye', 'kalite',        'Kalite',         6, true,  'verified',           '2E7D32'),
    ('boya_terbiye', 'sevkiyat',      'Sevkiyat',       7, true,  'local_shipping',     '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Baski desen asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('baski_desen', 'tasarim',    'Tasarım',         1, true,  'palette',            '7B1FA2'),
    ('baski_desen', 'sablon',     'Kalıp/Şablon',   2, true,  'straighten',         '6D4C41'),
    ('baski_desen', 'baski',      'Baskı',           3, true,  'print',              'E65100'),
    ('baski_desen', 'kurutma',    'Kurutma',         4, true,  'air',                '00838F'),
    ('baski_desen', 'fiksaj',     'Fiksaj',          5, true,  'thermostat',         'AD1457'),
    ('baski_desen', 'kalite',     'Kalite',          6, true,  'verified',           '2E7D32'),
    ('baski_desen', 'sevkiyat',   'Sevkiyat',        7, true,  'local_shipping',     '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Iplik uretim asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('iplik_uretim', 'hammadde_kabul', 'Hammadde Kabul', 1, true,  'inventory',        '6D4C41'),
    ('iplik_uretim', 'harman',         'Harman',          2, true,  'blender',          '00838F'),
    ('iplik_uretim', 'tarak',          'Tarak',           3, true,  'straighten',       '1976D2'),
    ('iplik_uretim', 'fitil',          'Fitil',           4, true,  'linear_scale',     '7B1FA2'),
    ('iplik_uretim', 'bukum',          'Büküm',           5, true,  'replay',           'E65100'),
    ('iplik_uretim', 'bobin',          'Bobin',           6, true,  'circle',           'AD1457'),
    ('iplik_uretim', 'kalite',         'Kalite',          7, true,  'verified',         '2E7D32'),
    ('iplik_uretim', 'sevkiyat',       'Sevkiyat',        8, true,  'local_shipping',   '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- Teknik tekstil asamalari
INSERT INTO asama_tanimlari (tekstil_dali, asama_kodu, asama_adi, sira_no, zorunlu, ikon, renk) VALUES
    ('teknik_tekstil', 'malzeme_secim',   'Malzeme Seçim',        1, true,  'category',         '6D4C41'),
    ('teknik_tekstil', 'uretim',          'Üretim',               2, true,  'precision_manufacturing', '1976D2'),
    ('teknik_tekstil', 'kaplama',         'Kaplama/Laminasyon',   3, false, 'layers',           '7B1FA2'),
    ('teknik_tekstil', 'test',            'Test',                 4, true,  'science',          '00838F'),
    ('teknik_tekstil', 'kalite',          'Kalite',               5, true,  'verified',         '2E7D32'),
    ('teknik_tekstil', 'sevkiyat',        'Sevkiyat',             6, true,  'local_shipping',   '1565C0')
ON CONFLICT (tekstil_dali, asama_kodu) DO NOTHING;

-- ---------------------------------------------------------
-- 6. SEED DATA: DAL FORM ALANLARI
-- ---------------------------------------------------------

-- Triko form alanlari
INSERT INTO dal_form_alanlari (tekstil_dali, alan_kodu, alan_adi, alan_tipi, secenekler, zorunlu, sira_no, grup) VALUES
    ('triko', 'triko_tipi',     'Triko Tipi',         'dropdown', '["Düz Örme","Jakar","İntarsia","Triko Kumaş","Rib","Dikişsiz"]', true,  1, 'Ürün Bilgisi'),
    ('triko', 'iplik_turu',     'İplik Türü',         'text',     NULL, true,  2, 'İplik'),
    ('triko', 'iplik_numarasi', 'İplik Numarası',     'text',     NULL, false, 3, 'İplik'),
    ('triko', 'iplik_kompozisyonu', 'İplik Kompozisyonu', 'text', NULL, false, 4, 'İplik'),
    ('triko', 'makine_tipi',    'Makine Tipi',        'dropdown', '["Düz Örme","Yuvarlak Örme","Jakar","Triko"]', false, 5, 'Makine'),
    ('triko', 'igne_inceligi',  'İğne İnceliği (Gauge)', 'number', NULL, false, 6, 'Makine'),
    ('triko', 'gramaj',         'Gramaj (g/m²)',      'number',   NULL, false, 7, 'Teknik')
ON CONFLICT (tekstil_dali, alan_kodu) DO NOTHING;

-- Konfeksiyon form alanlari
INSERT INTO dal_form_alanlari (tekstil_dali, alan_kodu, alan_adi, alan_tipi, secenekler, zorunlu, sira_no, grup) VALUES
    ('konfeksiyon', 'kumas_tipi',   'Kumaş Tipi',       'dropdown', '["Dokuma","Örme","Denim","Kadife","Keten","Polyester","Diğer"]', true, 1, 'Kumaş'),
    ('konfeksiyon', 'kumas_gramaj', 'Kumaş Gramajı (g/m²)', 'number', NULL, false, 2, 'Kumaş'),
    ('konfeksiyon', 'kumas_eni',    'Kumaş Eni (cm)',    'number',   NULL, false, 3, 'Kumaş'),
    ('konfeksiyon', 'kalip_tipi',   'Kalıp Tipi',       'dropdown', '["Regular Fit","Slim Fit","Oversize","Loose Fit","Diğer"]', false, 4, 'Üretim'),
    ('konfeksiyon', 'dikim_tipi',   'Dikim Tipi',       'dropdown', '["Overlok","Düz Dikiş","Zincir Dikiş","Flatlock","Diğer"]', false, 5, 'Üretim'),
    ('konfeksiyon', 'astar',        'Astar Var mı?',    'checkbox',  NULL, false, 6, 'Detay')
ON CONFLICT (tekstil_dali, alan_kodu) DO NOTHING;

-- Dokuma kumas form alanlari
INSERT INTO dal_form_alanlari (tekstil_dali, alan_kodu, alan_adi, alan_tipi, secenekler, zorunlu, sira_no, grup) VALUES
    ('dokuma_kumas', 'cozgu_iplik',  'Çözgü İpliği',    'text',     NULL, true,  1, 'İplik'),
    ('dokuma_kumas', 'atki_iplik',   'Atkı İpliği',     'text',     NULL, true,  2, 'İplik'),
    ('dokuma_kumas', 'dokuma_tipi',  'Dokuma Tipi',     'dropdown', '["Bezayağı","Dimi","Saten","Jakar","Dobby","Diğer"]', true, 3, 'Teknik'),
    ('dokuma_kumas', 'en_cm',        'Kumaş Eni (cm)',  'number',   NULL, true,  4, 'Teknik'),
    ('dokuma_kumas', 'gramaj',       'Gramaj (g/m²)',   'number',   NULL, false, 5, 'Teknik'),
    ('dokuma_kumas', 'sikligi',      'Sıklığı (tel/cm)', 'text',   NULL, false, 6, 'Teknik')
ON CONFLICT (tekstil_dali, alan_kodu) DO NOTHING;

-- Orme kumas form alanlari
INSERT INTO dal_form_alanlari (tekstil_dali, alan_kodu, alan_adi, alan_tipi, secenekler, zorunlu, sira_no, grup) VALUES
    ('orme_kumas', 'iplik_cinsi',   'İplik Cinsi',     'text',     NULL, true,  1, 'İplik'),
    ('orme_kumas', 'orme_tipi',     'Örme Tipi',       'dropdown', '["Süprem","Ribana","İnterlok","Lacoste","Polar","Diğer"]', true, 2, 'Teknik'),
    ('orme_kumas', 'makine_tipi',   'Makine Tipi',     'dropdown', '["Yuvarlak Örme","Düz Örme","Çözgülü Örme"]', false, 3, 'Makine'),
    ('orme_kumas', 'en_cm',         'Kumaş Eni (cm)',  'number',   NULL, false, 4, 'Teknik'),
    ('orme_kumas', 'gramaj',        'Gramaj (g/m²)',   'number',   NULL, false, 5, 'Teknik')
ON CONFLICT (tekstil_dali, alan_kodu) DO NOTHING;

-- Boya terbiye form alanlari
INSERT INTO dal_form_alanlari (tekstil_dali, alan_kodu, alan_adi, alan_tipi, secenekler, zorunlu, sira_no, grup) VALUES
    ('boya_terbiye', 'kumas_tipi',   'Kumaş Tipi',       'dropdown', '["Dokuma","Örme","Denim","İplik","Diğer"]', true, 1, 'Malzeme'),
    ('boya_terbiye', 'boya_tipi',    'Boya Tipi',        'dropdown', '["Reaktif","Dispers","Küp","Asit","Pigment","Diğer"]', true, 2, 'Boya'),
    ('boya_terbiye', 'renk_kodu',    'Renk Kodu',        'text',     NULL, true,  3, 'Boya'),
    ('boya_terbiye', 'islem_tipi',   'İşlem Tipi',       'dropdown', '["Boyama","Ağartma","Yıkama","Apre","Sanfor","Diğer"]', false, 4, 'İşlem'),
    ('boya_terbiye', 'sicaklik',     'Sıcaklık (°C)',    'number',   NULL, false, 5, 'Teknik')
ON CONFLICT (tekstil_dali, alan_kodu) DO NOTHING;

DO $$ BEGIN RAISE NOTICE 'Asama 8 SQL tamamlandi: Genel uretim altyapisi, asama tanimlari ve form alanlari olusturuldu.'; END $$;
