-- Triko Takip tablosuna fiyatlandırma kolonları ekleme
-- Bu script model_ekle.dart'da kullanılan yeni kolonları ekler

ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS model_adi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS sezon TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS koleksiyon TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS urun_kategorisi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS triko_tipi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS cinsiyet TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS yas_grubu TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS yaka_tipi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS kol_tipi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS ana_iplik_turu TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_karisimi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_kalinligi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_markasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_renk_kodu TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_numarasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS desen_tipi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS desen_detayi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS renk_kombinasyonu TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS toplam_adet INTEGER;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS gramaj TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS orgu_firmasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_tedarikci TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS boyahane TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS ilik_dugme_metal_aksesuar TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS konfeksiyon_firmasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS utu_pres_firmasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS yikama_firmasi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS makine_tipi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS igne_no TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS gauge TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS orgu_sikligi TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS teknik_gramaj TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS termin_tarihi TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS durum TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS ozel_talimatlar TEXT;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS genel_notlar TEXT;

-- Fiyatlandırma kolonları
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_kg_fiyati DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS iplik_maliyeti DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS makina_cikis_suresi DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS makina_dk_fiyati DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS orgu_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS dikim_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS utu_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS yikama_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS ilik_dugme_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS fermuar_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS aksesuar_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS genel_aksesuar_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS genel_gider_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS kar_marji DECIMAL(5,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS pesin_fiyat DECIMAL(10,2);
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS vade_ay INTEGER DEFAULT 0;
ALTER TABLE public.triko_takip ADD COLUMN IF NOT EXISTS vade_orani DECIMAL(5,2);

-- Yorum: Bu script çalıştırıldıktan sonra model_ekle.dart'daki tüm kolonlar veritabanında mevcut olacak