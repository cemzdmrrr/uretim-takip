-- Üretim Takip Projesi için Kapsamlı Veritabanı Şeması
-- Tüm model ve kod analizi sonucunda belirlenen tablolar


CREATE TABLE IF NOT EXISTS public.user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'kullanici' CHECK (role IN ('admin', 'yonetici', 'kullanici', 'personel')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Kullanıcılar tablosu (uygulama içi profil bilgileri için)
CREATE TABLE IF NOT EXISTS public.kullanicilar (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    ad_soyad TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    telefon TEXT,
    rol TEXT NOT NULL DEFAULT 'kullanici' CHECK (rol IN ('admin', 'yonetici', 'kullanici', 'personel')),
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Adminler tablosu (isteğe bağlı, sadece adminleri listelemek için)
CREATE TABLE IF NOT EXISTS public.adminler (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    ad_soyad TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    telefon TEXT,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- PERSONEL YÖNETİMİ
-- ==========================================

-- Personel tablosu
CREATE TABLE IF NOT EXISTS public.personel (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    ad_soyad TEXT NOT NULL,
    tckn TEXT UNIQUE,
    pozisyon TEXT,
    departman TEXT,
    email TEXT,
    telefon TEXT,
    ise_baslangic DATE,
    brut_maas DECIMAL(10,2),
    sgk_sicil_no TEXT,
    gunluk_calisma_saati DECIMAL(4,2) DEFAULT 8,
    haftalik_calisma_gunu INTEGER DEFAULT 5,
    yol_ucreti DECIMAL(10,2) DEFAULT 0,
    yemek_ucreti DECIMAL(10,2) DEFAULT 0,
    ekstra_prim DECIMAL(10,2) DEFAULT 0,
    elden_maas DECIMAL(10,2) DEFAULT 0,
    banka_maas DECIMAL(10,2) DEFAULT 0,
    adres TEXT,
    net_maas DECIMAL(10,2),
    yillik_izin_hakki INTEGER DEFAULT 14,
    durum TEXT DEFAULT 'aktif',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- İzinler
CREATE TABLE IF NOT EXISTS public.izinler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID NOT NULL REFERENCES public.personel(user_id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    izin_turu TEXT NOT NULL,
    baslangic DATE NOT NULL,
    bitis DATE NOT NULL,
    gun_sayisi INTEGER NOT NULL,
    aciklama TEXT,
    onay_durumu TEXT DEFAULT 'beklemede' CHECK (onay_durumu IN ('beklemede', 'onaylandi', 'red')),
    onaylayan_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mesai kayıtları
CREATE TABLE IF NOT EXISTS public.mesai (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID NOT NULL REFERENCES public.personel(user_id) ON DELETE CASCADE,
    tarih DATE NOT NULL,
    baslangic_saati TIME NOT NULL,
    bitis_saati TIME NOT NULL,
    saat DECIMAL(4,2),
    mesai_turu TEXT NOT NULL,
    mesai_ucret DECIMAL(10,2),
    onay_durumu TEXT DEFAULT 'beklemede' CHECK (onay_durumu IN ('beklemede', 'onaylandi', 'red')),
    onaylayan_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ödeme kayıtları
CREATE TABLE IF NOT EXISTS public.odeme_kayitlari (
    id BIGSERIAL PRIMARY KEY,
    personel_id UUID NOT NULL REFERENCES public.personel(user_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tur TEXT NOT NULL CHECK (tur IN ('avans', 'prim', 'mesai', 'ikramiye', 'kesinti')),
    tutar DECIMAL(10,2) NOT NULL,
    aciklama TEXT,
    tarih DATE NOT NULL,
    durum TEXT DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'red')),
    onaylayan_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Puantaj
CREATE TABLE IF NOT EXISTS public.puantaj (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID NOT NULL REFERENCES public.personel(user_id) ON DELETE CASCADE,
    ad TEXT NOT NULL,
    ay INTEGER NOT NULL,
    yil INTEGER NOT NULL,
    gun INTEGER DEFAULT 0,
    calisma_saati INTEGER DEFAULT 0,
    fazla_mesai INTEGER DEFAULT 0,
    eksik_gun INTEGER DEFAULT 0,
    devamsizlik INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(personel_id, ay, yil)
);

-- Bordro
CREATE TABLE IF NOT EXISTS public.bordro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    personel_id UUID NOT NULL REFERENCES public.personel(user_id) ON DELETE CASCADE,
    donem_kodu TEXT NOT NULL,
    brut_maas DECIMAL(10,2) NOT NULL,
    ek_kesinti DECIMAL(10,2) DEFAULT 0,
    ek_odenek DECIMAL(10,2) DEFAULT 0,
    kazanc_toplam DECIMAL(10,2),
    yasal_kesinti DECIMAL(10,2),
    ozel_kesinti DECIMAL(10,2),
    calisma_gunu INTEGER DEFAULT 0,
    net_maas DECIMAL(10,2),
    aciklama TEXT,
    onaylandi BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(personel_id, donem_kodu)
);

-- Dönemler
CREATE TABLE IF NOT EXISTS public.donemler (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kod TEXT UNIQUE NOT NULL,
    ad TEXT NOT NULL,
    baslangic_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    aktif BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- MÜŞTERİ YÖNETİMİ
-- ==========================================

-- Müşteriler
CREATE TABLE IF NOT EXISTS public.musteriler (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    soyad TEXT,
    sirket TEXT,
    telefon TEXT NOT NULL,
    email TEXT,
    adres TEXT,
    il TEXT,
    ilce TEXT,
    posta_kodu TEXT,
    vergi_no TEXT,
    vergi_dairesi TEXT,
    musteri_tipi TEXT NOT NULL DEFAULT 'bireysel' CHECK (musteri_tipi IN ('bireysel', 'kurumsal')),
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif', 'askida')),
    notlar TEXT,
    kredi_limiti DECIMAL(15,2),
    bakiye DECIMAL(15,2) DEFAULT 0,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- TEDARİKÇİ YÖNETİMİ
-- ==========================================

-- Tedarikçiler
CREATE TABLE IF NOT EXISTS public.tedarikciler (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    soyad TEXT,
    sirket TEXT,
    telefon TEXT NOT NULL,
    email TEXT,
    tedarikci_tipi TEXT NOT NULL DEFAULT 'Üretici' CHECK (tedarikci_tipi IN ('Üretici', 'İthalatçı', 'Distribütör', 'Bayi', 'Hizmet Sağlayıcı', 'Diğer')),
    faaliyet TEXT CHECK (faaliyet IN ('Tekstil', 'İplik', 'Aksesuar', 'Makine', 'Kimyasal', 'Ambalaj', 'Lojistik', 'Diğer')),
    durum TEXT DEFAULT 'aktif' CHECK (durum IN ('aktif', 'pasif', 'beklemede')),
    vergi_no TEXT,
    tc_kimlik TEXT,
    iban_no TEXT,
    kayit_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tedarikçi siparişleri
CREATE TABLE IF NOT EXISTS public.tedarikci_siparisleri (
    id BIGSERIAL PRIMARY KEY,
    tedarikci_id BIGINT NOT NULL REFERENCES public.tedarikciler(id) ON DELETE CASCADE,
    siparis_no TEXT,
    siparis_tarihi DATE NOT NULL,
    teslim_tarihi DATE,
    toplam_tutar DECIMAL(15,2),
    durum TEXT DEFAULT 'beklemede',
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tedarikçi ödemeleri
CREATE TABLE IF NOT EXISTS public.tedarikci_odemeleri (
    id BIGSERIAL PRIMARY KEY,
    tedarikci_id BIGINT NOT NULL REFERENCES public.tedarikciler(id) ON DELETE CASCADE,
    tutar DECIMAL(15,2) NOT NULL,
    odeme_tarihi DATE NOT NULL,
    odeme_sekli TEXT,
    aciklama TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- ÜRETİM TAKİP SİSTEMİ
-- ==========================================

-- Ana sipariş/model tablosu (triko_takip)
CREATE TABLE IF NOT EXISTS public.triko_takip (
    id BIGSERIAL PRIMARY KEY,
    marka TEXT NOT NULL,
    item_no TEXT NOT NULL,
    renk TEXT,
    urun_cinsi TEXT,
    iplik_cinsi TEXT,
    uretici TEXT,
    adet INTEGER DEFAULT 0,
    yuklenen_adet INTEGER DEFAULT 0,
    bedenler JSONB,
    termin TIMESTAMP WITH TIME ZONE,
    tamamlandi BOOLEAN DEFAULT false,
    musteri_id BIGINT REFERENCES public.musteriler(id),
    siparis_tarihi TIMESTAMP WITH TIME ZONE,
    siparis_notu TEXT,
    toplam_maliyet DECIMAL(15,2),
    kur TEXT DEFAULT 'TRY',
    
    -- Üretim aşamaları
    iplik_geldi BOOLEAN DEFAULT false,
    iplik_tarihi TIMESTAMP WITH TIME ZONE,
    kase_onayi BOOLEAN DEFAULT false,
    orgu_firma JSONB,
    konfeksiyon_firma JSONB,
    utu_firma JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Yükleme kayıtları
CREATE TABLE IF NOT EXISTS public.yukleme_kayitlari (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    adet INTEGER NOT NULL,
    tarih TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Fire kayıtları
CREATE TABLE IF NOT EXISTS public.fire_kayitlari (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    asama TEXT NOT NULL CHECK (asama IN ('orgu', 'konfeksiyon', 'utu', 'diger')),
    adet INTEGER NOT NULL,
    tarih TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- FATURA SİSTEMİ
-- ==========================================

-- Faturalar
CREATE TABLE IF NOT EXISTS public.faturalar (
    fatura_id BIGSERIAL PRIMARY KEY,
    fatura_no TEXT UNIQUE NOT NULL,
    fatura_turu TEXT NOT NULL CHECK (fatura_turu IN ('satis', 'alis', 'iade', 'proforma')),
    fatura_tarihi DATE NOT NULL,
    musteri_id BIGINT REFERENCES public.musteriler(id),
    tedarikci_id BIGINT REFERENCES public.tedarikciler(id),
    fatura_adres TEXT NOT NULL,
    vergi_dairesi TEXT,
    vergi_no TEXT,
    ara_toplam_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    kdv_tutari DECIMAL(15,2) NOT NULL DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL DEFAULT 0,
    durum TEXT DEFAULT 'taslak' CHECK (durum IN ('taslak', 'onaylandi', 'iptal', 'gonderildi')),
    aciklama TEXT,
    vade_tarihi DATE,
    odeme_durumu TEXT DEFAULT 'odenmedi' CHECK (odeme_durumu IN ('odenmedi', 'kismi', 'odendi')),
    odenen_tutar DECIMAL(15,2) DEFAULT 0,
    kur TEXT DEFAULT 'TRY',
    kur_orani DECIMAL(10,4) DEFAULT 1,
    efatura_uuid TEXT,
    efatura_tarihi TIMESTAMP WITH TIME ZONE,
    efatura_durum TEXT,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    olusturan_kullanici TEXT NOT NULL
);

-- Fatura kalemleri
CREATE TABLE IF NOT EXISTS public.fatura_kalemleri (
    kalem_id BIGSERIAL PRIMARY KEY,
    fatura_id BIGINT NOT NULL REFERENCES public.faturalar(fatura_id) ON DELETE CASCADE,
    sira_no INTEGER NOT NULL,
    urun_kodu TEXT,
    urun_adi TEXT NOT NULL,
    aciklama TEXT,
    miktar DECIMAL(10,2) NOT NULL,
    birim TEXT DEFAULT 'adet',
    birim_fiyat DECIMAL(15,2) NOT NULL,
    iskonto DECIMAL(5,2) DEFAULT 0,
    iskonto_tutar DECIMAL(15,2) DEFAULT 0,
    kdv_orani DECIMAL(5,2) DEFAULT 20,
    kdv_tutar DECIMAL(15,2) NOT NULL,
    satir_tutar DECIMAL(15,2) NOT NULL,
    model_id BIGINT REFERENCES public.triko_takip(id),
    stok_id BIGINT,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- KASA BANKA YÖNETİMİ
-- ==========================================

-- Kasa/Banka hesapları
CREATE TABLE IF NOT EXISTS public.kasa_banka_hesaplari (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    tip TEXT NOT NULL CHECK (tip IN ('KASA', 'BANKA', 'KREDI_KARTI', 'CEK_HESABI')),
    banka_adi TEXT,
    hesap_no TEXT,
    iban TEXT,
    sube_kodu TEXT,
    sube_adi TEXT,
    bakiye DECIMAL(15,2) DEFAULT 0,
    doviz_turu TEXT DEFAULT 'TRY',
    durumu TEXT DEFAULT 'AKTIF' CHECK (durumu IN ('AKTIF', 'PASIF', 'DONUK')),
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Kasa/Banka hareketleri
CREATE TABLE IF NOT EXISTS public.kasa_banka_hareketleri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kasa_banka_id BIGINT NOT NULL REFERENCES public.kasa_banka_hesaplari(id) ON DELETE CASCADE,
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer_giden', 'transfer_gelen')),
    tutar DECIMAL(15,2) NOT NULL,
    doviz_turu TEXT DEFAULT 'TRY',
    aciklama TEXT,
    kategori TEXT CHECK (kategori IN ('fatura_odeme', 'nakit_giris', 'bank_transfer', 'operasyonel', 'diger')),
    fatura_id BIGINT REFERENCES public.faturalar(fatura_id),
    hedef_kasa_banka_id BIGINT REFERENCES public.kasa_banka_hesaplari(id),
    referans_no TEXT,
    islem_tarihi TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_by TEXT NOT NULL,
    onaylanmis_mi BOOLEAN DEFAULT false,
    onaylayan_kullanici TEXT,
    onaylama_tarihi TIMESTAMP WITH TIME ZONE,
    notlar TEXT
);

-- ==========================================
-- STOK YÖNETİMİ
-- ==========================================

-- İplik stokları
CREATE TABLE IF NOT EXISTS public.iplik_stoklari (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    renk TEXT,
    lot_no TEXT,
    miktar DECIMAL(10,2) DEFAULT 0,
    birim TEXT DEFAULT 'kg',
    birim_fiyat DECIMAL(10,2),
    toplam_deger DECIMAL(15,2),
    tedarikci_id BIGINT REFERENCES public.tedarikciler(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- İplik hareketleri
CREATE TABLE IF NOT EXISTS public.iplik_hareketleri (
    id BIGSERIAL PRIMARY KEY,
    iplik_id BIGINT NOT NULL REFERENCES public.iplik_stoklari(id) ON DELETE CASCADE,
    hareket_tipi TEXT NOT NULL CHECK (hareket_tipi IN ('giris', 'cikis', 'transfer', 'sayim')),
    miktar DECIMAL(10,2) NOT NULL,
    kalan_miktar DECIMAL(10,2),
    aciklama TEXT,
    model_id BIGINT REFERENCES public.triko_takip(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Aksesuarlar
CREATE TABLE IF NOT EXISTS public.aksesuarlar (
    id BIGSERIAL PRIMARY KEY,
    ad TEXT NOT NULL,
    kategori TEXT,
    stok_adet INTEGER DEFAULT 0,
    birim_fiyat DECIMAL(10,2),
    resim_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Aksesuar bedenleri
CREATE TABLE IF NOT EXISTS public.aksesuar_beden (
    id BIGSERIAL PRIMARY KEY,
    aksesuar_id BIGINT NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
    beden TEXT NOT NULL,
    adet INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Model-Aksesuar ilişkisi
CREATE TABLE IF NOT EXISTS public.model_aksesuar (
    id BIGSERIAL PRIMARY KEY,
    model_id BIGINT NOT NULL REFERENCES public.triko_takip(id) ON DELETE CASCADE,
    aksesuar_id BIGINT NOT NULL REFERENCES public.aksesuarlar(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(model_id, aksesuar_id)
);

-- ==========================================
-- SİSTEM AYARLARI
-- ==========================================

-- Şirket bilgileri
CREATE TABLE IF NOT EXISTS public.sirket_bilgileri (
    id BIGSERIAL PRIMARY KEY,
    sirket_adi TEXT NOT NULL,
    vergi_no TEXT,
    vergi_dairesi TEXT,
    adres TEXT,
    telefon TEXT,
    email TEXT,
    website TEXT,
    logo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Sistem ayarları
CREATE TABLE IF NOT EXISTS public.sistem_ayarlari (
    id BIGSERIAL PRIMARY KEY,
    anahtar TEXT UNIQUE NOT NULL,
    deger TEXT,
    aciklama TEXT,
    kategori TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Gelir vergisi dilimleri
CREATE TABLE IF NOT EXISTS public.gelir_vergisi_dilimleri (
    id BIGSERIAL PRIMARY KEY,
    alt_sinir DECIMAL(15,2) NOT NULL,
    ust_sinir DECIMAL(15,2),
    oran DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- ENVANTER YÖNETİMİ
-- ==========================================

-- Envanter tablosu
CREATE TABLE IF NOT EXISTS public.envanter (
    id BIGSERIAL PRIMARY KEY,
    urun_adi TEXT NOT NULL,
    kategori TEXT NOT NULL,
    miktar DECIMAL(10,2) NOT NULL DEFAULT 0,
    birim TEXT NOT NULL DEFAULT 'adet',
    kritik_seviye DECIMAL(10,2) NOT NULL DEFAULT 10,
    max_stok DECIMAL(10,2) NOT NULL DEFAULT 1000,
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- İŞ TAKİP SİSTEMİ
-- ==========================================

-- İş takip tablosu
CREATE TABLE IF NOT EXISTS public.is_takip (
    id BIGSERIAL PRIMARY KEY,
    baslik TEXT NOT NULL,
    aciklama TEXT,
    durum TEXT NOT NULL DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'devam_ediyor', 'tamamlandi', 'iptal')),
    oncelik TEXT NOT NULL DEFAULT 'normal' CHECK (oncelik IN ('dusuk', 'normal', 'yuksek', 'kritik')),
    atanan_personel_id UUID REFERENCES public.personel(user_id),
    proje_id BIGINT,
    baslama_tarihi TIMESTAMP WITH TIME ZONE,
    bitis_tarihi TIMESTAMP WITH TIME ZONE,
    tamamlanma_tarihi TIMESTAMP WITH TIME ZONE,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ==========================================
-- RLS (ROW LEVEL SECURITY) POLİTİKALARI
-- ==========================================

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kullanicilar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adminler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesai ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.puantaj ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bordro ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.musteriler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikciler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikci_siparisleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tedarikci_odemeleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.yukleme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fire_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fatura_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_stoklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.iplik_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aksesuarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aksesuar_beden ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_aksesuar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sirket_bilgileri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gelir_vergisi_dilimleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.envanter ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.is_takip ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi verilerine erişebilir" ON public.user_roles FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Kullanıcılar kendi profilini görebilir ve güncelleyebilir" ON public.kullanicilar FOR ALL USING (auth.uid() = id);
CREATE POLICY "Adminler kendi profilini görebilir ve güncelleyebilir" ON public.adminler FOR ALL USING (auth.uid() = id);
CREATE POLICY "Kullanıcılar kendi bildirimlerine erişebilir" ON public.notifications FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Herkes personel verilerini okuyabilir" ON public.personel FOR SELECT USING (true);
CREATE POLICY "Herkes izin verilerini okuyabilir" ON public.izinler FOR SELECT USING (true);
CREATE POLICY "Herkes mesai verilerini okuyabilir" ON public.mesai FOR SELECT USING (true);
CREATE POLICY "Herkes ödeme verilerini okuyabilir" ON public.odeme_kayitlari FOR SELECT USING (true);
CREATE POLICY "Herkes puantaj verilerini okuyabilir" ON public.puantaj FOR SELECT USING (true);
CREATE POLICY "Herkes bordro verilerini okuyabilir" ON public.bordro FOR SELECT USING (true);
CREATE POLICY "Herkes dönem verilerini okuyabilir" ON public.donemler FOR SELECT USING (true);
CREATE POLICY "Herkes müşteri verilerini okuyabilir" ON public.musteriler FOR SELECT USING (true);
CREATE POLICY "Herkes tedarikçi verilerini okuyabilir" ON public.tedarikciler FOR SELECT USING (true);
CREATE POLICY "Herkes sipariş verilerini okuyabilir" ON public.triko_takip FOR SELECT USING (true);
CREATE POLICY "Herkes fatura verilerini okuyabilir" ON public.faturalar FOR SELECT USING (true);
CREATE POLICY "Herkes kasa/banka verilerini okuyabilir" ON public.kasa_banka_hesaplari FOR SELECT USING (true);
CREATE POLICY "Herkes stok verilerini okuyabilir" ON public.iplik_stoklari FOR SELECT USING (true);
CREATE POLICY "Herkes aksesuar verilerini okuyabilir" ON public.aksesuarlar FOR SELECT USING (true);
CREATE POLICY "Herkes envanter verilerini okuyabilir" ON public.envanter FOR SELECT USING (true);
CREATE POLICY "Herkes iş takip verilerini okuyabilir" ON public.is_takip FOR SELECT USING (true);

CREATE POLICY "Admin ve yönetici tüm işlemleri yapabilir" ON public.personel FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'yonetici')
    )
);

-- Adminler tüm kullanıcılarda tam yetkili
CREATE POLICY "Adminler tüm kullanıcılarda tam yetkili" ON public.kullanicilar FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    )
);

-- Adminler adminler tablosunda tam yetkili
CREATE POLICY "Adminler adminler tablosunda tam yetkili" ON public.adminler FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    )
);

-- ==========================================
-- TETİKLEYİCİLER VE FONKSİYONLAR
-- ==========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Fatura güncelleme fonksiyonu (önce tanımlanmalı)
CREATE OR REPLACE FUNCTION update_faturalar_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.guncelleme_tarihi = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_musteriler_updated_at ON public.musteriler;
CREATE TRIGGER update_musteriler_updated_at BEFORE UPDATE ON public.musteriler FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tedarikciler_updated_at ON public.tedarikciler;
CREATE TRIGGER update_tedarikciler_updated_at BEFORE UPDATE ON public.tedarikciler FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_triko_takip_updated_at ON public.triko_takip;
CREATE TRIGGER update_triko_takip_updated_at BEFORE UPDATE ON public.triko_takip FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_faturalar_updated_at ON public.faturalar;
CREATE TRIGGER update_faturalar_updated_at BEFORE UPDATE ON public.faturalar FOR EACH ROW EXECUTE FUNCTION update_faturalar_updated_at_column();

-- ==========================================
-- İNDEXLER
-- ==========================================

-- Performance için indeksler
CREATE INDEX IF NOT EXISTS idx_personel_tckn ON public.personel(tckn);
CREATE INDEX IF NOT EXISTS idx_personel_email ON public.personel(email);
CREATE INDEX IF NOT EXISTS idx_musteriler_telefon ON public.musteriler(telefon);
CREATE INDEX IF NOT EXISTS idx_musteriler_vergi_no ON public.musteriler(vergi_no);
CREATE INDEX IF NOT EXISTS idx_tedarikciler_telefon ON public.tedarikciler(telefon);
CREATE INDEX IF NOT EXISTS idx_triko_takip_marka ON public.triko_takip(marka);
CREATE INDEX IF NOT EXISTS idx_triko_takip_item_no ON public.triko_takip(item_no);
CREATE INDEX IF NOT EXISTS idx_triko_takip_musteri_id ON public.triko_takip(musteri_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_no ON public.faturalar(fatura_no);
CREATE INDEX IF NOT EXISTS idx_faturalar_musteri_id ON public.faturalar(musteri_id);
CREATE INDEX IF NOT EXISTS idx_faturalar_tedarikci_id ON public.faturalar(tedarikci_id);
CREATE INDEX IF NOT EXISTS idx_yukleme_kayitlari_model_id ON public.yukleme_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_fire_kayitlari_model_id ON public.fire_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_izinler_personel_id ON public.izinler(personel_id);
CREATE INDEX IF NOT EXISTS idx_mesai_personel_id ON public.mesai(personel_id);
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_personel_id ON public.odeme_kayitlari(personel_id);
CREATE INDEX IF NOT EXISTS idx_envanter_kategori ON public.envanter(kategori);
CREATE INDEX IF NOT EXISTS idx_envanter_miktar ON public.envanter(miktar);
CREATE INDEX IF NOT EXISTS idx_is_takip_durum ON public.is_takip(durum);
CREATE INDEX IF NOT EXISTS idx_is_takip_personel ON public.is_takip(atanan_personel_id);
CREATE INDEX IF NOT EXISTS idx_is_takip_oncelik ON public.is_takip(oncelik);

-- ==========================================
-- BAŞLANGIÇ VERİLERİ
-- ==========================================

-- Sistem ayarları
INSERT INTO public.sistem_ayarlari (anahtar, deger, aciklama, kategori) VALUES
('sgk_isveren_payi', '15.5', 'SGK İşveren Payı (%)', 'bordro'),
('sgk_iscisi_payi', '14', 'SGK İşçi Payı (%)', 'bordro'),
('issizlik_isveren_payi', '2', 'İşsizlik İşveren Payı (%)', 'bordro'),
('issizlik_iscisi_payi', '1', 'İşsizlik İşçi Payı (%)', 'bordro'),
('damga_vergisi', '0.759', 'Damga Vergisi (%)', 'bordro'),
('gelir_vergisi_muafiyet', '22000', 'Gelir Vergisi Muafiyet Tutarı (Yıllık)', 'bordro'),
('asgari_ucret', '17002', 'Asgari Ücret (Brüt)', 'bordro')
ON CONFLICT (anahtar) DO NOTHING;

-- Gelir vergisi dilimleri (2024)
INSERT INTO public.gelir_vergisi_dilimleri (alt_sinir, ust_sinir, oran) VALUES
(0, 110000, 15),
(110000, 230000, 20),
(230000, 580000, 27),
(580000, 3000000, 35),
(3000000, NULL, 40)
ON CONFLICT DO NOTHING;

-- Varsayılan dönem
INSERT INTO public.donemler (kod, ad, baslangic_tarihi, bitis_tarihi, aktif) VALUES
('2024-12', 'Aralık 2024', '2024-12-01', '2024-12-31', true)
ON CONFLICT (kod) DO NOTHING;

-- ==========================================
-- VIEWS (CREATE AFTER ALL TABLES)
-- ==========================================

-- Müşteri sipariş özeti (view olarak)
CREATE OR REPLACE VIEW public.musteri_siparis_ozet AS
SELECT 
    m.id,
    m.ad,
    m.soyad,
    m.sirket,
    m.musteri_tipi,
    COUNT(t.id) as toplam_siparis,
    SUM(CASE WHEN t.tamamlandi = true THEN 1 ELSE 0 END) as tamamlanan_siparis,
    SUM(t.adet) as toplam_adet,
    SUM(t.yuklenen_adet) as toplam_yuklenen_adet,
    SUM(t.toplam_maliyet) as toplam_maliyet
FROM public.musteriler m
LEFT JOIN public.triko_takip t ON m.id = t.musteri_id
GROUP BY m.id, m.ad, m.soyad, m.sirket, m.musteri_tipi;
