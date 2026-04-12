-- =============================================
-- TEMEL TABLOLAR - TÜM UYGULAMA TABLOLARI
-- =============================================

-- 1. KULLANICI ROLLERI
CREATE TABLE IF NOT EXISTS user_roles (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. KASA BANKA HESAPLARI
CREATE TABLE IF NOT EXISTS kasa_banka_hesaplari (
    id SERIAL PRIMARY KEY,
    hesap_adi VARCHAR(100) NOT NULL,
    hesap_no VARCHAR(50),
    iban VARCHAR(34),
    tip VARCHAR(20) DEFAULT 'banka',
    durumu VARCHAR(20) DEFAULT 'aktif',
    doviz_kodu VARCHAR(5) DEFAULT 'TRY',
    bakiye DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. KASA BANKA HAREKETLERI
CREATE TABLE IF NOT EXISTS kasa_banka_hareketleri (
    id SERIAL PRIMARY KEY,
    hesap_id INTEGER REFERENCES kasa_banka_hesaplari(id),
    kasa_banka_id INTEGER REFERENCES kasa_banka_hesaplari(id),
    hareket_tarihi DATE NOT NULL,
    hareket_tipi VARCHAR(20) DEFAULT 'giris',
    islem_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    kategori VARCHAR(50),
    aciklama TEXT,
    giren_tutar DECIMAL(15,2) DEFAULT 0,
    cikan_tutar DECIMAL(15,2) DEFAULT 0,
    bakiye DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. MÜŞTERİLER
CREATE TABLE IF NOT EXISTS musteriler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    sirket_adi VARCHAR(255),
    telefon VARCHAR(20),
    email VARCHAR(100),
    adres TEXT,
    vergi_no VARCHAR(20),
    tc_kimlik_no VARCHAR(11),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. TEDARİKÇİLER
CREATE TABLE IF NOT EXISTS tedarikciler (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    sirket_adi VARCHAR(255) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    tedarikci_turu VARCHAR(100) NOT NULL,
    faaliyet_alani VARCHAR(100) NOT NULL,
    durum VARCHAR(50) NOT NULL,
    vergi_no VARCHAR(20),
    tc_kimlik_no VARCHAR(11),
    iban_no VARCHAR(34),
    banka_hesap_no VARCHAR(50),
    iban VARCHAR(34),
    banka_adi VARCHAR(100),
    sube_kodu VARCHAR(20),
    sube_adi VARCHAR(100),
    banka_subesi VARCHAR(100),
    cep_telefonu VARCHAR(20),
    web_sitesi VARCHAR(255),
    yetkili_kisi VARCHAR(100),
    iskonto_orani DECIMAL(5,2) DEFAULT 0,
    mevcut_borc DECIMAL(15,2) DEFAULT 0,
    hesap_sahibi VARCHAR(100),
    notlar TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    varsayilan_iskonto DECIMAL(5,2) DEFAULT 0,
    toplam_borc DECIMAL(15,2) DEFAULT 0,
    son_odeme_tarihi DATE,
    faks VARCHAR(20),
    adres TEXT,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. MODELLER
CREATE TABLE IF NOT EXISTS modeller (
    id SERIAL PRIMARY KEY,
    model_adi VARCHAR(255) NOT NULL,
    model_kodu VARCHAR(100) UNIQUE,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. FATURALAR
CREATE TABLE IF NOT EXISTS faturalar (
    fatura_id SERIAL PRIMARY KEY,
    fatura_no VARCHAR(50) UNIQUE NOT NULL,
    fatura_turu VARCHAR(20) DEFAULT 'satis',
    fatura_tarihi DATE NOT NULL,
    musteri_id INTEGER REFERENCES musteriler(id),
    tedarikci_id INTEGER REFERENCES tedarikciler(id),
    fatura_adres TEXT NOT NULL,
    vergi_dairesi VARCHAR(100),
    vergi_no VARCHAR(20),
    ara_toplam_tutar DECIMAL(15,2) DEFAULT 0,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) DEFAULT 0,
    durum VARCHAR(20) DEFAULT 'taslak',
    aciklama TEXT,
    vade_tarihi DATE,
    odeme_durumu VARCHAR(20) DEFAULT 'odenmedi',
    odenen_tutar DECIMAL(15,2) DEFAULT 0,
    kur VARCHAR(5) DEFAULT 'TRY',
    kur_orani DECIMAL(10,4) DEFAULT 1.0000,
    efatura_uuid VARCHAR(36),
    efatura_tarihi TIMESTAMP,
    efatura_durum VARCHAR(20),
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    guncelleme_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    olusturan_kullanici VARCHAR(100)
);

-- 8. FATURA KALEMLERİ
CREATE TABLE IF NOT EXISTS fatura_kalemleri (
    id SERIAL PRIMARY KEY,
    fatura_id INTEGER REFERENCES faturalar(fatura_id) ON DELETE CASCADE,
    model_id INTEGER REFERENCES modeller(id),
    urun_adi VARCHAR(255) NOT NULL,
    urun_kodu VARCHAR(100),
    miktar DECIMAL(10,3) NOT NULL,
    birim VARCHAR(20) DEFAULT 'adet',
    birim_fiyat DECIMAL(15,2) NOT NULL,
    iskonto_orani DECIMAL(5,2) DEFAULT 0,
    iskonto_tutari DECIMAL(15,2) DEFAULT 0,
    kdv_orani DECIMAL(5,2) DEFAULT 20,
    kdv_tutari DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) NOT NULL,
    aciklama TEXT,
    olusturma_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. PERSONEL
CREATE TABLE IF NOT EXISTS personel (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL,
    soyad VARCHAR(100) NOT NULL,
    tc_kimlik_no VARCHAR(11) UNIQUE,
    telefon VARCHAR(20),
    email VARCHAR(100),
    adres TEXT,
    maas DECIMAL(15,2) DEFAULT 0,
    baslama_tarihi DATE,
    durum VARCHAR(20) DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. TRIKO TAKIPA
CREATE TABLE IF NOT EXISTS triko_takip (
    id SERIAL PRIMARY KEY,
    musteri_id INTEGER REFERENCES musteriler(id),
    model_id INTEGER REFERENCES modeller(id),
    siparis_tarihi DATE NOT NULL,
    teslim_tarihi DATE,
    durum VARCHAR(50) DEFAULT 'beklemede',
    miktar INTEGER DEFAULT 0,
    birim_fiyat DECIMAL(15,2) DEFAULT 0,
    toplam_tutar DECIMAL(15,2) DEFAULT 0,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. AKSESUARLAR
CREATE TABLE IF NOT EXISTS aksesuarlar (
    id SERIAL PRIMARY KEY,
    aksesuar_adi VARCHAR(255) NOT NULL,
    aksesuar_kodu VARCHAR(100) UNIQUE,
    birim VARCHAR(20) DEFAULT 'adet',
    stok_miktari INTEGER DEFAULT 0,
    birim_fiyat DECIMAL(15,2) DEFAULT 0,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. PUANTAJ
CREATE TABLE IF NOT EXISTS puantaj (
    id SERIAL PRIMARY KEY,
    personel_id INTEGER REFERENCES personel(id),
    tarih DATE NOT NULL,
    giris_saati TIME,
    cikis_saati TIME,
    toplam_saat DECIMAL(4,2) DEFAULT 0,
    mesai_saati DECIMAL(4,2) DEFAULT 0,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. MESAI
CREATE TABLE IF NOT EXISTS mesai (
    id SERIAL PRIMARY KEY,
    personel_id INTEGER REFERENCES personel(id),
    tarih DATE NOT NULL,
    mesai_saati DECIMAL(4,2) DEFAULT 0,
    saat_ucreti DECIMAL(10,2) DEFAULT 0,
    toplam_ucret DECIMAL(15,2) DEFAULT 0,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. İZİNLER
CREATE TABLE IF NOT EXISTS izinler (
    id SERIAL PRIMARY KEY,
    personel_id INTEGER REFERENCES personel(id),
    izin_turu VARCHAR(50) NOT NULL,
    baslama_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    gun_sayisi INTEGER NOT NULL,
    aciklama TEXT,
    onay_durumu VARCHAR(20) DEFAULT 'beklemede',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. BORDRO
CREATE TABLE IF NOT EXISTS bordro (
    id SERIAL PRIMARY KEY,
    personel_id INTEGER REFERENCES personel(id),
    donem VARCHAR(20) NOT NULL,
    temel_maas DECIMAL(15,2) DEFAULT 0,
    mesai_ucreti DECIMAL(15,2) DEFAULT 0,
    prim DECIMAL(15,2) DEFAULT 0,
    kesintiler DECIMAL(15,2) DEFAULT 0,
    net_maas DECIMAL(15,2) DEFAULT 0,
    odeme_tarihi DATE,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. DÖNEMLER
CREATE TABLE IF NOT EXISTS donemler (
    id SERIAL PRIMARY KEY,
    kod VARCHAR(20) UNIQUE NOT NULL,
    ad VARCHAR(100) NOT NULL,
    baslama_tarihi DATE NOT NULL,
    bitis_tarihi DATE NOT NULL,
    aktif BOOLEAN DEFAULT false,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 17. ŞİRKET BİLGİLERİ
CREATE TABLE IF NOT EXISTS sirket_bilgileri (
    id SERIAL PRIMARY KEY,
    sirket_adi VARCHAR(255) NOT NULL,
    vergi_no VARCHAR(20) UNIQUE NOT NULL,
    vergi_dairesi VARCHAR(100),
    adres TEXT,
    telefon VARCHAR(20),
    email VARCHAR(100),
    web_sitesi VARCHAR(255),
    logo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 18. ODEME KAYITLARI
CREATE TABLE IF NOT EXISTS odeme_kayitlari (
    id SERIAL PRIMARY KEY,
    odeme_turu VARCHAR(50) NOT NULL,
    referans_id INTEGER,
    tutar DECIMAL(15,2) NOT NULL,
    odeme_yontemi VARCHAR(50),
    odeme_tarihi DATE NOT NULL,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 19. SISTEM AYARLARI
CREATE TABLE IF NOT EXISTS sistem_ayarlari (
    id SERIAL PRIMARY KEY,
    anahtar VARCHAR(100) UNIQUE NOT NULL,
    deger TEXT,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 20. LOGLAR
CREATE TABLE IF NOT EXISTS loglar (
    id SERIAL PRIMARY KEY,
    kullanici_id UUID REFERENCES auth.users(id),
    islem VARCHAR(255) NOT NULL,
    detay TEXT,
    ip_adres VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGER FUNCTIONS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS
CREATE TRIGGER update_kasa_banka_hesaplari_updated_at
    BEFORE UPDATE ON kasa_banka_hesaplari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tedarikciler_updated_at
    BEFORE UPDATE ON tedarikciler
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_musteriler_updated_at
    BEFORE UPDATE ON musteriler
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_faturalar_updated_at
    BEFORE UPDATE ON faturalar
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_triko_takip_updated_at
    BEFORE UPDATE ON triko_takip
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_personel_updated_at
    BEFORE UPDATE ON personel
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_donemler_updated_at
    BEFORE UPDATE ON donemler
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sirket_bilgileri_updated_at
    BEFORE UPDATE ON sirket_bilgileri
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sistem_ayarlari_updated_at
    BEFORE UPDATE ON sistem_ayarlari
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
