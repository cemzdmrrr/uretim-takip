-- SADECE TABLOLAR - POLİTİKA YOK

-- 1. Dosyalar tablosu
CREATE TABLE IF NOT EXISTS dosyalar (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ad VARCHAR(255) NOT NULL,
    dosya_turu VARCHAR(20) DEFAULT 'pdf' CHECK (dosya_turu IN ('pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'folder')),
    boyut BIGINT DEFAULT 0,
    yol TEXT NOT NULL,
    ust_klasor_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    aciklama TEXT,
    olusturan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    olusturma_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    guncelleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true,
    genel_erisim BOOLEAN DEFAULT false,
    son_erisim_tarihi TIMESTAMP WITH TIME ZONE,
    erisim_sayisi INTEGER DEFAULT 0,
    mime_type VARCHAR(100)
);

-- 2. Dosya paylaşımları tablosu
CREATE TABLE IF NOT EXISTS dosya_paylasimlari (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dosya_id UUID REFERENCES dosyalar(id) ON DELETE CASCADE,
    paylasan_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    hedef_kullanici_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    izin_turu VARCHAR(20) DEFAULT 'read' CHECK (izin_turu IN ('read', 'write', 'admin')),
    paylasim_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    aktif BOOLEAN DEFAULT true
);

-- 3. Indexler
CREATE INDEX IF NOT EXISTS idx_dosyalar_ust_klasor ON dosyalar(ust_klasor_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_olusturan ON dosyalar(olusturan_kullanici_id) WHERE aktif = true;
CREATE INDEX IF NOT EXISTS idx_dosyalar_dosya_turu ON dosyalar(dosya_turu) WHERE aktif = true;

-- Başarılı mesajı
SELECT 'Tablolar başarıyla oluşturuldu!' as mesaj;
