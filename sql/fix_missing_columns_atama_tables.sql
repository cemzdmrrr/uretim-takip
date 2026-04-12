-- Dokuma atamalari tablosuna eksik kolonları ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS red_sebebi text;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS uretim_baslangic_tarihi timestamp with time zone;
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

-- Diğer atama tablolarında eksik adet kolonu ekle 
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;  
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS adet integer;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS talep_edilen_adet integer;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS tamamlanan_adet integer;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

ALTER TABLE nakis_atamalari ADD COLUMN IF NOT EXISTS kabul_edilen_adet integer;

-- Nakis atamalari tablosunda model_id tipini UUID'ye çevir (şu anda text)
ALTER TABLE nakis_atamalari ALTER COLUMN model_id TYPE uuid USING model_id::uuid;

-- Kalite kontrol atamalari tablosuna eksik kolonları ekle
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS onay_tarihi timestamp with time zone;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS red_sebebi text;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS onceki_asama text;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS onceki_atama_id uuid;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS kalite_sonucu text;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS kalite_notlari text;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS kalite_tarihi timestamp with time zone;
ALTER TABLE kalite_kontrol_atamalari ADD COLUMN IF NOT EXISTS kalite_personeli_id uuid;

-- Tüm atama tablolarına uretici_notlari kolonu ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;
ALTER TABLE nakis_atamalari ADD COLUMN IF NOT EXISTS uretici_notlari text;

-- Tüm atama tablolarına tamamlama_tarihi kolonu ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;
ALTER TABLE nakis_atamalari ADD COLUMN IF NOT EXISTS tamamlama_tarihi timestamp with time zone;