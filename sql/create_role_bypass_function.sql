-- RLS bypass için function oluşturun
-- Bu kodu Supabase SQL Editor'da çalıştırın

CREATE OR REPLACE FUNCTION public.get_user_role_bypass(user_id_param UUID)
RETURNS TABLE(role TEXT, aktif BOOLEAN)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT ur.role::TEXT, ur.aktif
  FROM public.user_roles ur
  WHERE ur.user_id = user_id_param
  LIMIT 1;
END;
$$;