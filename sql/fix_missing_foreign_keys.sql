-- EKSİK FOREIGN KEY'LER VE İLİŞKİ SORUNLARI

-- ÖNCE EKSİK PRIMARY KEY'LERİ GÜVENLE DÜZELT
-- 1. İplik stoklarında eksik primary key ekle (sadece yoksa)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_stoklari' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE iplik_stoklari ADD CONSTRAINT iplik_stoklari_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- 2. İplik hareketlerinde de primary key olduğundan emin ol (sadece yoksa)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_hareketleri' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE iplik_hareketleri ADD CONSTRAINT iplik_hareketleri_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- 3. Foreign key'ler eklenirken önce veri tutarlılığını kontrol et
-- Yetim kayıtları temizle
DELETE FROM iplik_hareketleri 
WHERE iplik_id IS NOT NULL 
AND iplik_id NOT IN (SELECT id FROM iplik_stoklari);

DELETE FROM iplik_hareketleri 
WHERE model_id IS NOT NULL 
AND model_id NOT IN (SELECT id FROM triko_takip);

-- 4. Şimdi güvenli şekilde foreign key'leri ekle (sadece yoksa)
-- İplik hareketleri tablosunda eksik foreign key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_hareketleri' 
        AND constraint_name = 'iplik_hareketleri_iplik_id_fkey'
    ) THEN
        ALTER TABLE iplik_hareketleri
        ADD CONSTRAINT iplik_hareketleri_iplik_id_fkey 
        FOREIGN KEY (iplik_id) REFERENCES iplik_stoklari(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_hareketleri' 
        AND constraint_name = 'iplik_hareketleri_model_id_fkey'
    ) THEN
        ALTER TABLE iplik_hareketleri
        ADD CONSTRAINT iplik_hareketleri_model_id_fkey 
        FOREIGN KEY (model_id) REFERENCES triko_takip(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_hareketleri' 
        AND constraint_name = 'iplik_hareketleri_iplik_stok_id_fkey'
    ) THEN
        ALTER TABLE iplik_hareketleri
        ADD CONSTRAINT iplik_hareketleri_iplik_stok_id_fkey 
        FOREIGN KEY (iplik_stok_id) REFERENCES iplik_stoklari(id);
    END IF;
END $$;

-- 2. İplik siparişleri eksik foreign key (güvenli)
-- Önce yetim kayıtları temizle
DELETE FROM iplik_siparisleri 
WHERE tedarikci_id IS NOT NULL 
AND tedarikci_id NOT IN (SELECT id FROM tedarikciler);

DELETE FROM iplik_siparisleri 
WHERE orgu_firmasi_id IS NOT NULL 
AND orgu_firmasi_id NOT IN (SELECT id FROM atolyeler);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_siparisleri' 
        AND constraint_name = 'iplik_siparisleri_tedarikci_id_fkey'
    ) THEN
        ALTER TABLE iplik_siparisleri
        ADD CONSTRAINT iplik_siparisleri_tedarikci_id_fkey 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'iplik_siparisleri' 
        AND constraint_name = 'iplik_siparisleri_orgu_firmasi_id_fkey'
    ) THEN
        ALTER TABLE iplik_siparisleri
        ADD CONSTRAINT iplik_siparisleri_orgu_firmasi_id_fkey 
        FOREIGN KEY (orgu_firmasi_id) REFERENCES atolyeler(id);
    END IF;
END $$;

-- 3. İplik stokları eksik foreign key
DELETE FROM iplik_stoklari 
WHERE tedarikci_id IS NOT NULL 
AND tedarikci_id NOT IN (SELECT id FROM tedarikciler);

ALTER TABLE iplik_stoklari
ADD CONSTRAINT iplik_stoklari_tedarikci_id_fkey 
FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);

-- 4. Model aksesuar eksik foreign key
DELETE FROM model_aksesuar 
WHERE model_id IS NOT NULL 
AND model_id NOT IN (SELECT id FROM triko_takip);

DELETE FROM model_aksesuar 
WHERE aksesuar_id IS NOT NULL 
AND aksesuar_id NOT IN (SELECT id FROM aksesuarlar);

ALTER TABLE model_aksesuar
ADD CONSTRAINT model_aksesuar_aksesuar_id_fkey 
FOREIGN KEY (aksesuar_id) REFERENCES aksesuarlar(id);

ALTER TABLE model_aksesuar
ADD CONSTRAINT model_aksesuar_model_id_fkey 
FOREIGN KEY (model_id) REFERENCES triko_takip(id);

-- 5. Model aksesuar bedenler eksik foreign key  
-- NOT: Bu tabloyu fix_data_inconsistencies.sql'de UUID'ye çevireceğiz
-- Şimdilik pas geç

-- 6. Model workflow gecmisi eksik foreign key
DELETE FROM model_workflow_gecmisi 
WHERE model_id IS NOT NULL 
AND model_id NOT IN (SELECT id FROM triko_takip);

DELETE FROM model_workflow_gecmisi 
WHERE islem_yapan_user_id IS NOT NULL 
AND islem_yapan_user_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE model_workflow_gecmisi
ADD CONSTRAINT model_workflow_gecmisi_model_id_fkey 
FOREIGN KEY (model_id) REFERENCES triko_takip(id);

ALTER TABLE model_workflow_gecmisi
ADD CONSTRAINT model_workflow_gecmisi_islem_yapan_user_id_fkey 
FOREIGN KEY (islem_yapan_user_id) REFERENCES auth.users(id);

-- 7. Aksesuar stok hareketleri eksik foreign key
DELETE FROM aksesuar_stok_hareketleri 
WHERE kullanici_id IS NOT NULL 
AND kullanici_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE aksesuar_stok_hareketleri
ADD CONSTRAINT aksesuar_stok_hareketleri_kullanici_id_fkey 
FOREIGN KEY (kullanici_id) REFERENCES auth.users(id);

-- 8. Personel tablosu eksiklikleri
-- Yetim kayıtları temizle
DELETE FROM bordro 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM mesai 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM mesai 
WHERE onaylayan_user_id IS NOT NULL 
AND onaylayan_user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM izinler 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM izinler 
WHERE onaylayan_user_id IS NOT NULL 
AND onaylayan_user_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE bordro
ADD CONSTRAINT bordro_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE mesai
ADD CONSTRAINT mesai_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE mesai
ADD CONSTRAINT mesai_onaylayan_user_id_fkey 
FOREIGN KEY (onaylayan_user_id) REFERENCES auth.users(id);

ALTER TABLE izinler
ADD CONSTRAINT izinler_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE izinler
ADD CONSTRAINT izinler_onaylayan_user_id_fkey 
FOREIGN KEY (onaylayan_user_id) REFERENCES auth.users(id);

-- 9. Ödeme kayıtları eksiklikleri
DELETE FROM odeme_kayitlari 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM odeme_kayitlari 
WHERE onaylayan_user_id IS NOT NULL 
AND onaylayan_user_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE odeme_kayitlari
ADD CONSTRAINT odeme_kayitlari_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE odeme_kayitlari
ADD CONSTRAINT odeme_kayitlari_onaylayan_user_id_fkey 
FOREIGN KEY (onaylayan_user_id) REFERENCES auth.users(id);

-- 10. Ödemeler tablosu eksiklikleri
DELETE FROM odemeler 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM odemeler 
WHERE user_id IS NOT NULL 
AND user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM odemeler 
WHERE onaylayan_user_id IS NOT NULL 
AND onaylayan_user_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE odemeler
ADD CONSTRAINT odemeler_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE odemeler
ADD CONSTRAINT odemeler_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id);

-- 11. Personel dönem eksiklikleri
DELETE FROM personel_donem 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

ALTER TABLE personel_donem
ADD CONSTRAINT personel_donem_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

-- 12. Dosya paylaşımları eksiklikleri  
DELETE FROM dosya_paylasimlari 
WHERE paylasan_kullanici_id IS NOT NULL 
AND paylasan_kullanici_id NOT IN (SELECT id FROM auth.users);

DELETE FROM dosya_paylasimlari 
WHERE hedef_kullanici_id IS NOT NULL 
AND hedef_kullanici_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE dosya_paylasimlari
ADD CONSTRAINT dosya_paylasimlari_paylasan_kullanici_id_fkey 
FOREIGN KEY (paylasan_kullanici_id) REFERENCES auth.users(id);

ALTER TABLE dosya_paylasimlari
ADD CONSTRAINT dosya_paylasimlari_hedef_kullanici_id_fkey 
FOREIGN KEY (hedef_kullanici_id) REFERENCES auth.users(id);

-- 13. Dosyalar tablosu eksiklikleri
DELETE FROM dosyalar 
WHERE olusturan_kullanici_id IS NOT NULL 
AND olusturan_kullanici_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE dosyalar
ADD CONSTRAINT dosyalar_olusturan_kullanici_id_fkey 
FOREIGN KEY (olusturan_kullanici_id) REFERENCES auth.users(id);

-- 14. Personel arşiv eksiklikleri
DELETE FROM personel_arsiv 
WHERE personel_id IS NOT NULL 
AND personel_id NOT IN (SELECT user_id FROM personel WHERE user_id IS NOT NULL);

DELETE FROM personel_arsiv 
WHERE yukleyen_user_id IS NOT NULL 
AND yukleyen_user_id NOT IN (SELECT id FROM auth.users);

DELETE FROM personel_arsiv 
WHERE onaylayan_id IS NOT NULL 
AND onaylayan_id NOT IN (SELECT id FROM auth.users);

ALTER TABLE personel_arsiv
ADD CONSTRAINT personel_arsiv_personel_id_fkey 
FOREIGN KEY (personel_id) REFERENCES personel(user_id);

ALTER TABLE personel_arsiv
ADD CONSTRAINT personel_arsiv_onaylayan_id_fkey 
FOREIGN KEY (onaylayan_id) REFERENCES auth.users(id);

COMMIT;