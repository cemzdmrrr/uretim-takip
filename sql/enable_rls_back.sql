-- RLS'İ TEKRAR AÇMAK İÇİN
-- Flutter test ettikten sonra bu kodu çalıştırın

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

SELECT 'user_roles RLS tekrar açıldı' as durum;