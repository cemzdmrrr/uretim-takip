-- =============================================
-- MEVCUT TABLOLARI DÜZELTME VE TEST VERİLERİ
-- =============================================

-- Önce mevcut tabloları kontrol et
DO $$
BEGIN
    -- Kasa banka hesapları tablosu kontrolü
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kasa_banka_hesaplari') THEN
        -- Tabloda hesap_adi kolonu var mı kontrol et
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'kasa_banka_hesaplari' AND column_name = 'hesap_adi') THEN
            -- Eksik kolonları ekle
            ALTER TABLE kasa_banka_hesaplari 
            ADD COLUMN hesap_adi VARCHAR(100),
            ADD COLUMN hesap_no VARCHAR(50),
            ADD COLUMN iban VARCHAR(34),
            ADD COLUMN tip VARCHAR(20) DEFAULT 'banka',
            ADD COLUMN durumu VARCHAR(20) DEFAULT 'aktif',
            ADD COLUMN doviz_kodu VARCHAR(5) DEFAULT 'TRY',
            ADD COLUMN bakiye DECIMAL(15,2) DEFAULT 0;
        END IF;
    END IF;
END $$;

-- Mevcut verileri sil ve yeniden ekle
DELETE FROM fatura_kalemleri;
DELETE FROM faturalar;
DELETE FROM triko_takip;
DELETE FROM puantaj;
DELETE FROM mesai;
DELETE FROM izinler;
DELETE FROM bordro;
DELETE FROM odeme_kayitlari;
DELETE FROM kasa_banka_hareketleri;
DELETE FROM aksesuarlar;
DELETE FROM modeller;
DELETE FROM personel;
DELETE FROM musteriler;
DELETE FROM tedarikciler;
DELETE FROM kasa_banka_hesaplari;
DELETE FROM donemler;
DELETE FROM sirket_bilgileri;
DELETE FROM sistem_ayarlari;
DELETE FROM loglar;
DELETE FROM user_roles;

-- Test verilerini ekle
INSERT INTO kasa_banka_hesaplari (hesap_adi, hesap_no, iban, tip, bakiye) VALUES 
('Ana Kasa', 'KASA001', NULL, 'kasa', 50000.00),
('Ziraat Bankası', '12345678', 'TR12 0001 0012 3456 7890 1234 56', 'banka', 125000.00),
('İş Bankası', '87654321', 'TR87 0006 4000 0012 3456 7890 12', 'banka', 89000.00);

INSERT INTO musteriler (ad, soyad, sirket_adi, telefon, email, vergi_no) VALUES 
('Ahmet', 'Yılmaz', 'Yılmaz Tekstil Ltd. Şti.', '0212 555 0101', 'ahmet@yilmaztekstil.com', '1234567890'),
('Fatma', 'Kaya', 'Kaya Moda', '0532 444 0202', 'fatma@kayamoda.com', '0987654321'),
('Mehmet', 'Demir', 'Demir Konfeksiyon', '0505 333 0303', 'mehmet@demirkonf.com', '1122334455');

INSERT INTO tedarikciler (ad, soyad, sirket_adi, telefon, email, tedarikci_turu, faaliyet_alani, durum, vergi_no, iban_no) VALUES 
('Ali', 'Özkan', 'Özkan İplik San. Tic. Ltd. Şti.', '0212 555 1111', 'ali@ozkaniplik.com', 'Firma', 'İplik Üretimi', 'Aktif', '1111222233', 'TR12 0001 0001 0000 0000 0000 01'),
('Zeynep', 'Arslan', 'Arslan Aksesuar', '0532 444 2222', 'zeynep@arslanacc.com', 'Firma', 'Aksesuar', 'Aktif', '4444555566', 'TR12 0001 0001 0000 0000 0000 02'),
('Hasan', 'Çelik', 'Çelik Tekstil', '0505 333 3333', 'hasan@celiktekstil.com', 'Firma', 'Tekstil', 'Aktif', '7777888899', 'TR12 0001 0001 0000 0000 0000 03');

INSERT INTO modeller (model_adi, model_kodu, aciklama) VALUES 
('Klasik Triko', 'KT001', 'Standart klasik triko modeli'),
('Spor Triko', 'ST001', 'Spor giyim triko modeli'),
('Kazak Modeli', 'KM001', 'Kışlık kazak modeli'),
('Yelek Modeli', 'YM001', 'Yelek triko modeli');

INSERT INTO faturalar (fatura_no, fatura_turu, fatura_tarihi, musteri_id, fatura_adres, ara_toplam_tutar, kdv_tutari, toplam_tutar, durum) VALUES 
('SAT-2025-001', 'satis', '2025-01-15', 1, 'Yılmaz Tekstil Ltd. Şti.\nİstanbul/Beyoğlu', 10000.00, 2000.00, 12000.00, 'onaylandi'),
('SAT-2025-002', 'satis', '2025-01-20', 2, 'Kaya Moda\nAnkara/Çankaya', 7500.00, 1500.00, 9000.00, 'onaylandi'),
('ALI-2025-001', 'alis', '2025-01-10', NULL, 'Özkan İplik San. Tic. Ltd. Şti.\nBursa/Osmangazi', 5000.00, 1000.00, 6000.00, 'onaylandi');

INSERT INTO fatura_kalemleri (fatura_id, model_id, urun_adi, urun_kodu, miktar, birim_fiyat, toplam_tutar) VALUES 
(1, 1, 'Klasik Triko', 'KT001', 100, 100.00, 10000.00),
(2, 2, 'Spor Triko', 'ST001', 50, 150.00, 7500.00),
(3, 1, 'İplik Hammaddesi', 'IP001', 100, 50.00, 5000.00);

INSERT INTO personel (ad, soyad, tc_kimlik_no, telefon, maas, baslama_tarihi, durum) VALUES 
('Ayşe', 'Yıldız', '12345678901', '0532 111 1111', 8000.00, '2024-01-01', 'aktif'),
('Mustafa', 'Kara', '23456789012', '0505 222 2222', 9000.00, '2024-02-01', 'aktif'),
('Elif', 'Beyaz', '34567890123', '0532 333 3333', 7500.00, '2024-03-01', 'aktif');

INSERT INTO triko_takip (musteri_id, model_id, siparis_tarihi, teslim_tarihi, durum, miktar, birim_fiyat, toplam_tutar) VALUES 
(1, 1, '2025-01-01', '2025-01-15', 'tamamlandi', 100, 100.00, 10000.00),
(2, 2, '2025-01-05', '2025-01-20', 'tamamlandi', 50, 150.00, 7500.00),
(3, 3, '2025-01-10', '2025-01-25', 'devam-ediyor', 75, 120.00, 9000.00);

INSERT INTO aksesuarlar (aksesuar_adi, aksesuar_kodu, stok_miktari, birim_fiyat) VALUES 
('Düğme Set', 'DGM001', 1000, 2.50),
('Fermuar 20cm', 'FRM001', 500, 5.00),
('Elastik Bant', 'ELB001', 200, 3.00);

INSERT INTO donemler (kod, ad, baslama_tarihi, bitis_tarihi, aktif) VALUES 
('2025-01', 'Ocak 2025', '2025-01-01', '2025-01-31', true),
('2025-02', 'Şubat 2025', '2025-02-01', '2025-02-28', false),
('2025-03', 'Mart 2025', '2025-03-01', '2025-03-31', false);

INSERT INTO sirket_bilgileri (sirket_adi, vergi_no, vergi_dairesi, adres, telefon, email) VALUES 
('Akar Triko Takip Sistemi', '1234567890', 'Beyoğlu V.D.', 'İstanbul/Beyoğlu', '0212 555 0000', 'info@akartriko.com');

INSERT INTO sistem_ayarlari (anahtar, deger, aciklama) VALUES 
('kdv_orani', '20', 'Varsayılan KDV oranı'),
('para_birimi', 'TRY', 'Para birimi'),
('fatura_seri', 'SAT', 'Satış faturası seri numarası'),
('alis_fatura_seri', 'ALI', 'Alış faturası seri numarası');

-- Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TÜM VERİLER GERİ YÜKLENDİ!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Toplam Müşteri: %', (SELECT COUNT(*) FROM musteriler);
    RAISE NOTICE 'Toplam Tedarikçi: %', (SELECT COUNT(*) FROM tedarikciler);
    RAISE NOTICE 'Toplam Fatura: %', (SELECT COUNT(*) FROM faturalar);
    RAISE NOTICE 'Toplam Personel: %', (SELECT COUNT(*) FROM personel);
    RAISE NOTICE 'Toplam Sipariş: %', (SELECT COUNT(*) FROM triko_takip);
    RAISE NOTICE 'Toplam Aksesuar: %', (SELECT COUNT(*) FROM aksesuarlar);
    RAISE NOTICE '========================================';
END $$;
