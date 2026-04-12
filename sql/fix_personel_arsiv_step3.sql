-- ADIM 3: RLS politikalarını yeniden oluştur

-- RLS'yi etkinleştir
ALTER TABLE public.personel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.odeme_kayitlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personel_arsiv ENABLE ROW LEVEL SECURITY;

-- personel_arsiv tablosu politikaları
DROP POLICY IF EXISTS "Admin arşiv yönetebilir" ON public.personel_arsiv;
CREATE POLICY "Admin arşiv yönetebilir" ON public.personel_arsiv 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'ik')
    )
);

DROP POLICY IF EXISTS "Personel kendi arşivini görebilir" ON public.personel_arsiv;
CREATE POLICY "Personel kendi arşivini görebilir" ON public.personel_arsiv 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- odeme_kayitlari tablosu politikaları
DROP POLICY IF EXISTS "Admin ödeme yönetebilir" ON public.odeme_kayitlari;
CREATE POLICY "Admin ödeme yönetebilir" ON public.odeme_kayitlari 
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role IN ('admin', 'muhasebe')
    )
);

DROP POLICY IF EXISTS "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari;
CREATE POLICY "Personel kendi ödemelerini görebilir" ON public.odeme_kayitlari 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.user_roles 
        WHERE user_id = auth.uid() AND role = 'personel'
    ) AND
    personel_id = auth.uid()
);

-- Index'leri oluştur
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_personel_id ON public.odeme_kayitlari(personel_id);
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_tarih ON public.odeme_kayitlari(tarih);
CREATE INDEX IF NOT EXISTS idx_odeme_kayitlari_odeme_tarihi ON public.odeme_kayitlari(odeme_tarihi);

CREATE INDEX IF NOT EXISTS idx_personel_arsiv_personel_id ON public.personel_arsiv(personel_id);
CREATE INDEX IF NOT EXISTS idx_personel_arsiv_belge_turu ON public.personel_arsiv(belge_turu);

-- Trigger function'unu oluştur
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur
DROP TRIGGER IF EXISTS update_odeme_kayitlari_updated_at ON public.odeme_kayitlari;
CREATE TRIGGER update_odeme_kayitlari_updated_at
    BEFORE UPDATE ON public.odeme_kayitlari
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_personel_updated_at ON public.personel;
CREATE TRIGGER update_personel_updated_at
    BEFORE UPDATE ON public.personel
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
