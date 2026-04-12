-- Çeki Listesi Tablosu
-- Kolilenen/paketlenen ürünlerin takibi için

-- Tablo oluştur
CREATE TABLE IF NOT EXISTS public.ceki_listesi (
    id SERIAL PRIMARY KEY,
    model_id UUID REFERENCES triko_takip(id) ON DELETE SET NULL,
    koli_no VARCHAR(50),
    koli_adedi INTEGER DEFAULT 1,
    adet INTEGER,
    paketleme_tarihi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    gonderim_durumu VARCHAR(50) DEFAULT 'bekliyor', -- bekliyor, hazirlaniyor, gonderildi
    gonderim_tarihi TIMESTAMP WITH TIME ZONE,
    alici_bilgisi TEXT,
    kargo_firmasi VARCHAR(100),
    takip_no VARCHAR(100),
    notlar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Koli numarası için sequence
CREATE SEQUENCE IF NOT EXISTS ceki_koli_no_seq START 1;

-- Trigger: Otomatik koli numarası oluştur
CREATE OR REPLACE FUNCTION generate_koli_no()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.koli_no IS NULL OR NEW.koli_no = '' THEN
        NEW.koli_no := 'KOL-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(nextval('ceki_koli_no_seq')::text, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_koli_no ON ceki_listesi;
CREATE TRIGGER trg_generate_koli_no
    BEFORE INSERT ON ceki_listesi
    FOR EACH ROW
    EXECUTE FUNCTION generate_koli_no();

-- Trigger: updated_at güncellemesi
CREATE OR REPLACE FUNCTION update_ceki_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ceki_updated_at ON ceki_listesi;
CREATE TRIGGER trg_ceki_updated_at
    BEFORE UPDATE ON ceki_listesi
    FOR EACH ROW
    EXECUTE FUNCTION update_ceki_updated_at();

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_ceki_listesi_model ON ceki_listesi(model_id);
CREATE INDEX IF NOT EXISTS idx_ceki_listesi_durum ON ceki_listesi(gonderim_durumu);
CREATE INDEX IF NOT EXISTS idx_ceki_listesi_tarih ON ceki_listesi(paketleme_tarihi);
CREATE INDEX IF NOT EXISTS idx_ceki_listesi_koli_no ON ceki_listesi(koli_no);

-- RLS politikaları
ALTER TABLE ceki_listesi ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
DROP POLICY IF EXISTS "ceki_listesi_select" ON ceki_listesi;
CREATE POLICY "ceki_listesi_select" ON ceki_listesi
    FOR SELECT USING (true);

-- Herkes ekleme yapabilir (giriş yapmış kullanıcılar)
DROP POLICY IF EXISTS "ceki_listesi_insert" ON ceki_listesi;
CREATE POLICY "ceki_listesi_insert" ON ceki_listesi
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Herkes güncelleme yapabilir (giriş yapmış kullanıcılar)
DROP POLICY IF EXISTS "ceki_listesi_update" ON ceki_listesi;
CREATE POLICY "ceki_listesi_update" ON ceki_listesi
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Silme yetkisi (giriş yapmış kullanıcılar)
DROP POLICY IF EXISTS "ceki_listesi_delete" ON ceki_listesi;
CREATE POLICY "ceki_listesi_delete" ON ceki_listesi
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Yorum: Bu scripti Supabase SQL Editor'da çalıştırın
