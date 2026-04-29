begin;

alter table if exists public.user_roles
  add column if not exists firma_id uuid;

alter table if exists public.user_roles
  add column if not exists aktif boolean not null default true;

alter table if exists public.user_roles
  drop constraint if exists user_roles_role_check;

update public.user_roles
set aktif = true
where aktif is null;

update public.user_roles
set role = case lower(trim(coalesce(role, '')))
  when '' then 'kullanici'
  when 'user' then 'kullanici'
  when 'viewer' then 'kullanici'
  when 'platform_admin' then 'admin'
  when 'dokuma' then 'dokumaci'
  when 'dokumaci' then 'dokumaci'
  when 'konfeksiyon' then 'konfeksiyoncu'
  when 'konfeksiyoncu' then 'konfeksiyoncu'
  when 'kalite' then 'kalite_kontrol'
  when 'kalite kontrol' then 'kalite_kontrol'
  when 'kalite_kontrol' then 'kalite_kontrol'
  when 'depo' then 'depocu'
  when 'depocu' then 'depocu'
  when 'utu' then 'utu_paket'
  when 'ütü' then 'utu_paket'
  when 'utu paket' then 'utu_paket'
  when 'utu_paket' then 'utu_paket'
  when 'paketleme' then 'utu_paket'
  when 'ilik dugme' then 'ilik_dugme'
  when 'ilik_düğme' then 'ilik_dugme'
  when 'ilik_dugme' then 'ilik_dugme'
  when 'nakis' then 'nakis'
  when 'nakış' then 'nakis'
  when 'yikama' then 'yikama'
  when 'yıkama' then 'yikama'
  when 'sevkiyat' then 'sevkiyat'
  when 'sofor' then 'sofor'
  when 'şoför' then 'sofor'
  when 'muhasebeci' then 'muhasebeci'
  when 'personel' then 'personel'
  when 'yonetici' then 'yonetici'
  when 'yönetici' then 'yonetici'
  when 'firma_admin' then 'firma_admin'
  when 'firma_sahibi' then 'firma_sahibi'
  when 'admin' then 'admin'
  when 'kullanici' then 'kullanici'
  when 'kullanıcı' then 'kullanici'
  else 'kullanici'
end;

update public.user_roles ur
set firma_id = fk.firma_id
from public.firma_kullanicilari fk
where fk.user_id = ur.user_id
  and fk.aktif = true
  and ur.firma_id is null;

do $$
declare
  user_id_attnum smallint;
  c record;
begin
  select attnum
    into user_id_attnum
  from pg_attribute
  where attrelid = 'public.user_roles'::regclass
    and attname = 'user_id'
    and not attisdropped
  limit 1;

  if user_id_attnum is not null then
    for c in
      select conname
      from pg_constraint
      where conrelid = 'public.user_roles'::regclass
        and contype = 'u'
        and array_length(conkey, 1) = 1
        and conkey[1] = user_id_attnum
    loop
      execute format(
        'alter table public.user_roles drop constraint if exists %I',
        c.conname
      );
    end loop;
  end if;
end $$;

with ranked as (
  select
    ctid,
    row_number() over (
      partition by user_id, firma_id, role
      order by id
    ) as rn
  from public.user_roles
)
delete from public.user_roles ur
using ranked
where ur.ctid = ranked.ctid
  and ranked.rn > 1;

create index if not exists idx_user_roles_user_firma
  on public.user_roles (user_id, firma_id);

create index if not exists idx_user_roles_role_aktif
  on public.user_roles (role, aktif);

create unique index if not exists idx_user_roles_user_firma_role_unique
  on public.user_roles (user_id, firma_id, role)
  where firma_id is not null;

create unique index if not exists idx_user_roles_user_global_role_unique
  on public.user_roles (user_id, role)
  where firma_id is null;

alter table if exists public.user_roles
  add constraint user_roles_role_check
  check (
    role in (
      'admin',
      'firma_sahibi',
      'firma_admin',
      'yonetici',
      'kullanici',
      'personel',
      'dokumaci',
      'konfeksiyoncu',
      'kalite_kontrol',
      'sevkiyat',
      'sofor',
      'muhasebeci',
      'depocu',
      'nakis',
      'yikama',
      'utu_paket',
      'ilik_dugme'
    )
  );

commit;
