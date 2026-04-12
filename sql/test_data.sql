-- Test Verileri ve Örnek Kayıtlar

-- ==========================================
-- TEST VERİLERİ
-- ==========================================

-- Test müşterileri
INSERT INTO public.musteriler (ad, soyad, sirket, telefon, email, musteri_tipi, durum) VALUES
('Ahmet', 'Yılmaz', NULL, '0532 123 4567', 'ahmet@email.com', 'bireysel', 'aktif'),
('Fatma', 'Kaya', NULL, '0543 234 5678', 'fatma@email.com', 'bireysel', 'aktif'),
('', '', 'Tekstil A.Ş.', '0212 345 6789', 'info@tekstilas.com', 'kurumsal', 'aktif'),
('', '', 'Moda Konfeksiyon Ltd.', '0216 456 7890', 'siparis@modakonfeksiyon.com', 'kurumsal', 'aktif'),
('Mehmet', 'Özkan', NULL, '0555 567 8901', 'mehmet@email.com', 'bireysel', 'aktif')
ON CONFLICT DO NOTHING;

-- Test tedarikçileri
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum) VALUES
('Ali', 'Demir', NULL, '0532 111 2222', 'ali@email.com', 'Üretici', 'Tekstil', 'aktif'),
('', '', 'İplik San. A.Ş.', '0212 222 3333', 'info@ipliksan.com', 'Üretici', 'İplik', 'aktif'),
('Ayşe', 'Çelik', NULL, '0543 333 4444', 'ayse@email.com', 'Üretici', 'Aksesuar', 'aktif'),
('', '', 'Konfeksiyon Pro Ltd.', '0216 444 5555', 'uretim@konfeksiyonpro.com', 'Üretici', 'Tekstil', 'aktif'),
('Hasan', 'Yıldız', NULL, '0555 555 6666', 'hasan@email.com', 'Hizmet Sağlayıcı', 'Lojistik', 'aktif')
ON CONFLICT DO NOTHING;

-- Test siparişleri (triko_takip)
INSERT INTO public.triko_takip (marka, item_no, renk, urun_cinsi, iplik_cinsi, uretici, adet, musteri_id, bedenler, termin, siparis_tarihi) VALUES
('MANGO', 'MNG001', 'Siyah', 'Kazak', 'Pamuk', 'Tekstil A.Ş.', 100, 3, '{"S": 20, "M": 30, "L": 30, "XL": 20}', '2024-12-31', '2024-12-01'),
('ZARA', 'ZRA002', 'Beyaz', 'T-Shirt', 'Pamuk', 'Moda Konfeksiyon', 150, 4, '{"S": 30, "M": 50, "L": 40, "XL": 30}', '2024-12-25', '2024-12-02'),
('H&M', 'HM003', 'Lacivert', 'Pantolon', 'Kot', 'Tekstil A.Ş.', 75, 1, '{"28": 15, "30": 20, "32": 20, "34": 15, "36": 5}', '2024-12-20', '2024-12-03'),
('BERSHKA', 'BSK004', 'Kırmızı', 'Elbise', 'Polyester', 'Moda Konfeksiyon', 50, 2, '{"XS": 10, "S": 15, "M": 15, "L": 10}', '2024-12-28', '2024-12-04'),
('PULL&BEAR', 'PB005', 'Gri', 'Sweatshirt', 'Pamuk', 'Tekstil A.Ş.', 80, 5, '{"S": 20, "M": 25, "L": 25, "XL": 10}', '2024-12-30', '2024-12-05')
ON CONFLICT DO NOTHING;

-- Test kasa/banka hesapları
INSERT INTO public.kasa_banka_hesaplari (ad, tip, banka_adi, hesap_no, iban, bakiye, doviz_turu) VALUES
('Ana Kasa', 'KASA', NULL, NULL, NULL, 50000.00, 'TRY'),
('Garanti BBVA TL Hesabı', 'BANKA', 'Garanti BBVA', '1234567890', 'TR33 0062 0910 0000 0001 2345 67', 150000.00, 'TRY'),
('İş Bankası USD Hesabı', 'BANKA', 'Türkiye İş Bankası', '9876543210', 'TR55 0006 4000 0011 2345 6789 01', 25000.00, 'USD'),
('Kredi Kartı Hesabı', 'KREDI_KARTI', 'Yapı Kredi', '4568-****-****-1234', NULL, -5000.00, 'TRY'),
('Çek Hesabı', 'CEK_HESABI', 'Akbank', '5555666677', 'TR77 0004 6000 1234 5678 9012 34', 75000.00, 'TRY')
ON CONFLICT DO NOTHING;

-- Test iplik stokları
INSERT INTO public.iplik_stoklari (ad, renk, lot_no, miktar, birim, birim_fiyat, tedarikci_id) VALUES
('Pamuk İplik 20/1', 'Beyaz', 'LOT001', 500.00, 'kg', 45.50, 2),
('Pamuk İplik 30/1', 'Siyah', 'LOT002', 300.00, 'kg', 48.00, 2),
('Polyester İplik', 'Lacivert', 'LOT003', 200.00, 'kg', 35.00, 2),
('Kot İplik', 'İndigo', 'LOT004', 150.00, 'kg', 55.00, 2),
('Pamuk Karışım', 'Gri', 'LOT005', 400.00, 'kg', 42.00, 2)
ON CONFLICT DO NOTHING;

-- Test aksesuarlar
INSERT INTO public.aksesuarlar (ad, kategori, stok_adet, birim_fiyat) VALUES
('Plastik Düğme', 'Düğme', 5000, 0.50),
('Metal Fermuar', 'Fermuar', 1000, 3.50),
('Etiket', 'Etiket', 10000, 0.25),
('İplik Dikişi', 'Dikiş Malzemesi', 500, 2.00),
('Çıtçıt', 'Çıtçıt', 2000, 0.75)
ON CONFLICT DO NOTHING;

-- Test faturalar
INSERT INTO public.faturalar (fatura_no, fatura_turu, fatura_tarihi, musteri_id, fatura_adres, ara_toplam_tutar, kdv_tutari, toplam_tutar, olusturan_kullanici) VALUES
('FAT-2024-001', 'satis', '2024-12-01', 3, 'Tekstil A.Ş. İstanbul', 10000.00, 2000.00, 12000.00, 'admin'),
('FAT-2024-002', 'satis', '2024-12-02', 4, 'Moda Konfeksiyon Ltd. Ankara', 15000.00, 3000.00, 18000.00, 'admin'),
('FAT-2024-003', 'satis', '2024-12-03', 1, 'Ahmet Yılmaz - İstanbul', 5000.00, 1000.00, 6000.00, 'admin')
ON CONFLICT DO NOTHING;

-- Test fatura kalemleri
INSERT INTO public.fatura_kalemleri (fatura_id, sira_no, urun_adi, miktar, birim_fiyat, kdv_orani, kdv_tutar, satir_tutar) VALUES
(1, 1, 'MANGO Kazak - Siyah', 100, 100.00, 20, 2000.00, 12000.00),
(2, 1, 'ZARA T-Shirt - Beyaz', 150, 100.00, 20, 3000.00, 18000.00),
(3, 1, 'H&M Pantolon - Lacivert', 75, 66.67, 20, 1000.00, 6000.00)
ON CONFLICT DO NOTHING;

-- Test yükleme kayıtları
INSERT INTO public.yukleme_kayitlari (model_id, adet, tarih) VALUES
(1, 30, '2024-12-10'),
(1, 40, '2024-12-12'),
(2, 50, '2024-12-11'),
(3, 25, '2024-12-13'),
(4, 20, '2024-12-14')
ON CONFLICT DO NOTHING;

-- Test fire kayıtları
INSERT INTO public.fire_kayitlari (model_id, asama, adet, tarih) VALUES
(1, 'orgu', 3, '2024-12-10'),
(1, 'konfeksiyon', 2, '2024-12-12'),
(2, 'orgu', 5, '2024-12-11'),
(3, 'utu', 1, '2024-12-13')
ON CONFLICT DO NOTHING;

-- Test kasa/banka hareketleri
INSERT INTO public.kasa_banka_hareketleri (kasa_banka_id, hareket_tipi, tutar, aciklama, kategori, islem_tarihi, created_by) VALUES
(1, 'giris', 10000.00, 'Nakit satış geliri', 'nakit_giris', '2024-12-01', 'admin'),
(2, 'cikis', 5000.00, 'Tedarikçi ödemesi', 'fatura_odeme', '2024-12-02', 'admin'),
(1, 'cikis', 2000.00, 'Ofis giderleri', 'operasyonel', '2024-12-03', 'admin'),
(2, 'giris', 15000.00, 'Müşteri ödemesi', 'fatura_odeme', '2024-12-04', 'admin'),
(3, 'giris', 3000.00, 'USD giriş', 'bank_transfer', '2024-12-05', 'admin')
ON CONFLICT DO NOTHING;

-- Yüklenen adet güncellemesi (trigger ile normalde otomatik olmalı)
UPDATE public.triko_takip SET yuklenen_adet = (
    SELECT COALESCE(SUM(adet), 0) 
    FROM public.yukleme_kayitlari 
    WHERE model_id = triko_takip.id
);

-- Stok değer güncellemesi
UPDATE public.iplik_stoklari SET toplam_deger = miktar * birim_fiyat;

-- Kasa/banka bakiye güncellemesi (normalde trigger ile otomatik olmalı)
UPDATE public.kasa_banka_hesaplari SET bakiye = (
    SELECT COALESCE(
        50000 + -- başlangıç bakiyesi
        (SELECT COALESCE(SUM(CASE WHEN hareket_tipi IN ('giris', 'transfer_gelen') THEN tutar ELSE -tutar END), 0)
         FROM public.kasa_banka_hareketleri 
         WHERE kasa_banka_id = kasa_banka_hesaplari.id), 0), 0)
) WHERE id = 1;

UPDATE public.kasa_banka_hesaplari SET bakiye = (
    SELECT COALESCE(
        150000 + -- başlangıç bakiyesi
        (SELECT COALESCE(SUM(CASE WHEN hareket_tipi IN ('giris', 'transfer_gelen') THEN tutar ELSE -tutar END), 0)
         FROM public.kasa_banka_hareketleri 
         WHERE kasa_banka_id = kasa_banka_hesaplari.id), 0), 0)
) WHERE id = 2;
