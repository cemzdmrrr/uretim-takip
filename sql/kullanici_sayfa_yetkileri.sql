-- Kullanıcı bazlı sayfa yetki tablosu
CREATE TABLE IF NOT EXISTS public.kullanici_sayfa_yetkileri (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firma_id UUID NOT NULL REFERENCES public.firmalar(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  sayfa_kodu TEXT NOT NULL,
  aktif BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(firma_id, user_id, sayfa_kodu)
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_kullanici_sayfa_yetkileri_firma_user 
  ON public.kullanici_sayfa_yetkileri(firma_id, user_id);

-- RLS
ALTER TABLE public.kullanici_sayfa_yetkileri ENABLE ROW LEVEL SECURITY;

-- Admin policy
CREATE POLICY "Admin full access" ON public.kullanici_sayfa_yetkileri
  FOR ALL USING (true) WITH CHECK (true);
