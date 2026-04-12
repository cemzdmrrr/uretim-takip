-- Dokuma atamalari tablosuna tedarikci_id alanı ekle
ALTER TABLE dokuma_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;

-- Foreign key constraint ekle (tedarikciler tablosuna)
ALTER TABLE dokuma_atamalari 
ADD CONSTRAINT fk_dokuma_atamalari_tedarikci 
FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);

-- atanan_kullanici_id alanının null olabilmesini sağla
ALTER TABLE dokuma_atamalari ALTER COLUMN atanan_kullanici_id DROP NOT NULL;

-- Konfeksiyon atamalari tablosuna tedarikci_id alanı ekle (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'konfeksiyon_atamalari') THEN
        ALTER TABLE konfeksiyon_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
        ALTER TABLE konfeksiyon_atamalari 
        ADD CONSTRAINT fk_konfeksiyon_atamalari_tedarikci 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        ALTER TABLE konfeksiyon_atamalari ALTER COLUMN atanan_kullanici_id DROP NOT NULL;
    END IF;
END $$;

-- Nakis atamalari tablosuna tedarikci_id alanı ekle (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nakis_atamalari') THEN
        ALTER TABLE nakis_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
        ALTER TABLE nakis_atamalari 
        ADD CONSTRAINT fk_nakis_atamalari_tedarikci 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        -- nakis_atamalari zaten text tipinde model_id kullanıyor, farklı yapı
    END IF;
END $$;

-- Yikama atamalari tablosuna tedarikci_id alanı ekle (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'yikama_atamalari') THEN
        ALTER TABLE yikama_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
        ALTER TABLE yikama_atamalari 
        ADD CONSTRAINT fk_yikama_atamalari_tedarikci 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        ALTER TABLE yikama_atamalari ALTER COLUMN atanan_kullanici_id DROP NOT NULL;
    END IF;
END $$;

-- Ilik dugme atamalari tablosuna tedarikci_id alanı ekle (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ilik_dugme_atamalari') THEN
        ALTER TABLE ilik_dugme_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
        ALTER TABLE ilik_dugme_atamalari 
        ADD CONSTRAINT fk_ilik_dugme_atamalari_tedarikci 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        ALTER TABLE ilik_dugme_atamalari ALTER COLUMN atanan_kullanici_id DROP NOT NULL;
    END IF;
END $$;

-- Utu atamalari tablosuna tedarikci_id alanı ekle (varsa)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'utu_atamalari') THEN
        ALTER TABLE utu_atamalari ADD COLUMN IF NOT EXISTS tedarikci_id INTEGER;
        ALTER TABLE utu_atamalari 
        ADD CONSTRAINT fk_utu_atamalari_tedarikci 
        FOREIGN KEY (tedarikci_id) REFERENCES tedarikciler(id);
        ALTER TABLE utu_atamalari ALTER COLUMN atanan_kullanici_id DROP NOT NULL;
    END IF;
END $$;