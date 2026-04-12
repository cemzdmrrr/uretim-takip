-- VERİ TUTARSIZLIKLARI VE ÇÖZÜMLERİ

-- PROBLEM 1: model_aksesuar_bedenler.model_id INTEGER ama diğerleri UUID
-- ÇÖZÜM: Bu tabloyu düzelt
DROP TABLE IF EXISTS model_aksesuar_bedenler CASCADE;
CREATE TABLE model_aksesuar_bedenler (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id UUID NOT NULL, -- INTEGER'dan UUID'ye çevrildi
  aksesuar_beden_id UUID NOT NULL,
  kullanim_miktari NUMERIC NOT NULL DEFAULT 1,
  zorunlu BOOLEAN DEFAULT true,
  kullanim_yeri TEXT,
  sira_no INTEGER,
  notlar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT model_aksesuar_bedenler_model_id_fkey 
    FOREIGN KEY (model_id) REFERENCES triko_takip(id),
  CONSTRAINT model_aksesuar_bedenler_aksesuar_beden_id_fkey 
    FOREIGN KEY (aksesuar_beden_id) REFERENCES aksesuar_bedenler(id)
);

-- PROBLEM 2: aksesuar_stok_hareketleri.model_id INTEGER ama diğerleri UUID  
-- ÇÖZÜM: Model_id'yi UUID yap
ALTER TABLE aksesuar_stok_hareketleri 
DROP CONSTRAINT IF EXISTS aksesuar_stok_hareketleri_model_id_check;

ALTER TABLE aksesuar_stok_hareketleri 
ALTER COLUMN model_id TYPE UUID USING NULL;

ALTER TABLE aksesuar_stok_hareketleri
ADD CONSTRAINT aksesuar_stok_hareketleri_model_id_fkey 
FOREIGN KEY (model_id) REFERENCES triko_takip(id);

-- PROBLEM 3: fatura_kalemleri.model_id INTEGER ama ana model tablosu UUID
-- ÇÖZÜM: Fatura kalemlerini düzelt
ALTER TABLE fatura_kalemleri 
DROP CONSTRAINT IF EXISTS fatura_kalemleri_model_id_fkey;

ALTER TABLE fatura_kalemleri 
ALTER COLUMN model_id TYPE UUID USING NULL;

ALTER TABLE fatura_kalemleri
ADD CONSTRAINT fatura_kalemleri_model_id_fkey 
FOREIGN KEY (model_id) REFERENCES triko_takip(id);

-- PROBLEM 4: tedarikciler.tedarikci_tipi vs aksesuarlar.tedarikci_id tutarsızlığı
-- ÇÖZÜM: Tedarikci_id'yi düzelt
ALTER TABLE aksesuarlar 
DROP CONSTRAINT IF EXISTS aksesuarlar_tedarikci_id_fkey;

ALTER TABLE aksesuarlar 
ALTER COLUMN tedarikci_id TYPE INTEGER;

ALTER TABLE aksesuarlar
ADD CONSTRAINT aksesuarlar_tedarikci_id_fkey 
FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);

-- PROBLEM 5: Personel tablosundaki çoklu referans alanları
-- ÇÖZÜM: Gereksiz alanları temizle ve standartlaştır
ALTER TABLE mesai DROP COLUMN IF EXISTS personel_id;
ALTER TABLE mesai DROP COLUMN IF EXISTS onaylayan_id;
-- user_id ve onaylayan_user_id kullan

ALTER TABLE izinler DROP COLUMN IF EXISTS personel_id;
ALTER TABLE izinler DROP COLUMN IF EXISTS onaylayan_id;
-- user_id ve onaylayan_user_id kullan

ALTER TABLE odeme_kayitlari DROP COLUMN IF EXISTS personel_id;
ALTER TABLE odeme_kayitlari DROP COLUMN IF EXISTS onaylayan_id;
-- user_id ve onaylayan_user_id kullan

-- PROBLEM 6: Duplicated timestamp columns
-- Bazı tablolarda hem created_at hem de kayit_tarihi/olusturma_tarihi var
-- Bunları standartlaştır

-- PROBLEM 7: Enum değerleri tutarsızlığı
-- user_roles.role enum değerlerini kontrol et
-- Bazı atama tablolarında eksik enum değerleri olabilir

-- INDEX'ler ekle (Performance için kritik)
CREATE INDEX IF NOT EXISTS idx_triko_takip_item_no ON triko_takip(item_no);
CREATE INDEX IF NOT EXISTS idx_triko_takip_durum ON triko_takip(durum);
CREATE INDEX IF NOT EXISTS idx_triko_takip_marka ON triko_takip(marka);
CREATE INDEX IF NOT EXISTS idx_triko_takip_termin_tarihi ON triko_takip(termin_tarihi);

CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_model_id ON uretim_kayitlari(model_id);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_asama ON uretim_kayitlari(asama);
CREATE INDEX IF NOT EXISTS idx_uretim_kayitlari_durum ON uretim_kayitlari(durum);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);

CREATE INDEX IF NOT EXISTS idx_atolyeler_aktif ON atolyeler(aktif);
CREATE INDEX IF NOT EXISTS idx_atolyeler_atolye_turu ON atolyeler(atolye_turu);

COMMIT;