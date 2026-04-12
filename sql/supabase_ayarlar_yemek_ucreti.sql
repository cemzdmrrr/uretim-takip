-- Sistem ayarları tablosu - yemek ücretleri için
CREATE TABLE IF NOT EXISTS sistem_ayarlari (
  id SERIAL PRIMARY KEY,
  ayar_kodu VARCHAR(50) UNIQUE NOT NULL,
  ayar_adi VARCHAR(100) NOT NULL,
  ayar_degeri DECIMAL(10,2) NOT NULL,
  birim VARCHAR(20) DEFAULT 'TL',
  aciklama TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Varsayılan yemek ücretlerini ekle
INSERT INTO sistem_ayarlari (ayar_kodu, ayar_adi, ayar_degeri, birim, aciklama) VALUES
('PAZAR_YEMEK_UCRETI', 'Pazar Mesaisi Yemek Ücreti', 50.00, 'TL', 'Pazar günü mesai yapan personeller için yemek ücreti'),
('BAYRAM_YEMEK_UCRETI', 'Bayram Mesaisi Yemek Ücreti', 75.00, 'TL', 'Bayram günü mesai yapan personeller için yemek ücreti')
ON CONFLICT (ayar_kodu) DO NOTHING;

-- RLS politikaları
ALTER TABLE sistem_ayarlari ENABLE ROW LEVEL SECURITY;

-- Admin kullanıcılar tüm işlemleri yapabilir
CREATE POLICY "admin_full_access_sistem_ayarlari" ON sistem_ayarlari
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() 
    AND role = 'admin'
  )
);

-- Normal kullanıcılar sadece okuyabilir
CREATE POLICY "user_read_sistem_ayarlari" ON sistem_ayarlari
FOR SELECT USING (true);
