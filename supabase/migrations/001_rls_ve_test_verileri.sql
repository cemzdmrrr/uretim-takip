-- =============================================
-- RLS POLİTİKALARI VE TEST VERİLERİ
-- =============================================

-- RLS ENABLE
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kasa_banka_hesaplari ENABLE ROW LEVEL SECURITY;
ALTER TABLE kasa_banka_hareketleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE musteriler ENABLE ROW LEVEL SECURITY;
ALTER TABLE tedarikciler ENABLE ROW LEVEL SECURITY;
ALTER TABLE modeller ENABLE ROW LEVEL SECURITY;
ALTER TABLE faturalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE fatura_kalemleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE triko_takip ENABLE ROW LEVEL SECURITY;
ALTER TABLE aksesuarlar ENABLE ROW LEVEL SECURITY;
ALTER TABLE puantaj ENABLE ROW LEVEL SECURITY;
ALTER TABLE mesai ENABLE ROW LEVEL SECURITY;
ALTER TABLE izinler ENABLE ROW LEVEL SECURITY;
ALTER TABLE bordro ENABLE ROW LEVEL SECURITY;
ALTER TABLE donemler ENABLE ROW LEVEL SECURITY;
ALTER TABLE sirket_bilgileri ENABLE ROW LEVEL SECURITY;
ALTER TABLE odeme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE sistem_ayarlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE loglar ENABLE ROW LEVEL SECURITY;

-- GENEL OKUMA POLİTİKALARI
CREATE POLICY "Herkes okuyabilir" ON user_roles FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON kasa_banka_hesaplari FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON kasa_banka_hareketleri FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON musteriler FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON tedarikciler FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON modeller FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON faturalar FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON fatura_kalemleri FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON personel FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON triko_takip FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON aksesuarlar FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON puantaj FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON mesai FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON izinler FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON bordro FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON donemler FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON sirket_bilgileri FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON odeme_kayitlari FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON sistem_ayarlari FOR SELECT USING (true);
CREATE POLICY "Herkes okuyabilir" ON loglar FOR SELECT USING (true);

-- INSERT/UPDATE/DELETE POLİTİKALARI
CREATE POLICY "Herkes ekleyebilir" ON user_roles FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON kasa_banka_hesaplari FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON kasa_banka_hareketleri FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON musteriler FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON tedarikciler FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON modeller FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON faturalar FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON fatura_kalemleri FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON personel FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON triko_takip FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON aksesuarlar FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON puantaj FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON mesai FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON izinler FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON bordro FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON donemler FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON sirket_bilgileri FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON odeme_kayitlari FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON sistem_ayarlari FOR INSERT WITH CHECK (true);
CREATE POLICY "Herkes ekleyebilir" ON loglar FOR INSERT WITH CHECK (true);

CREATE POLICY "Herkes güncelleyebilir" ON user_roles FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON kasa_banka_hesaplari FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON kasa_banka_hareketleri FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON musteriler FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON tedarikciler FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON modeller FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON faturalar FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON fatura_kalemleri FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON personel FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON triko_takip FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON aksesuarlar FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON puantaj FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON mesai FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON izinler FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON bordro FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON donemler FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON sirket_bilgileri FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON odeme_kayitlari FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON sistem_ayarlari FOR UPDATE USING (true);
CREATE POLICY "Herkes güncelleyebilir" ON loglar FOR UPDATE USING (true);

CREATE POLICY "Herkes silebilir" ON user_roles FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON kasa_banka_hesaplari FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON kasa_banka_hareketleri FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON musteriler FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON tedarikciler FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON modeller FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON faturalar FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON fatura_kalemleri FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON personel FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON triko_takip FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON aksesuarlar FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON puantaj FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON mesai FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON izinler FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON bordro FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON donemler FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON sirket_bilgileri FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON odeme_kayitlari FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON sistem_ayarlari FOR DELETE USING (true);
CREATE POLICY "Herkes silebilir" ON loglar FOR DELETE USING (true);

-- TEST VERİLERİ ATLANACAK - BAŞKA DOSYADA YAPILACAK

-- VERİLER BAŞKA DOSYADA YAPILACAK

-- İNDEKSLER BAŞKA DOSYADA YAPILACAK
