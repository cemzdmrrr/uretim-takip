alter table public.aksesuarlar
  add column if not exists tedarikci_id integer references public.tedarikciler(id) on delete set null;

create index if not exists idx_aksesuarlar_firma_tedarikci
  on public.aksesuarlar (firma_id, tedarikci_id);

create or replace function public.aksesuar_tedarikci_firma_kontrolu()
returns trigger
language plpgsql
as $$
begin
  if new.tedarikci_id is not null and not exists (
    select 1
    from public.tedarikciler t
    where t.id = new.tedarikci_id
      and t.firma_id = new.firma_id
  ) then
    raise exception 'Tedarikci aksesuar ile ayni firmaya ait olmalidir';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_aksesuar_tedarikci_firma_kontrolu on public.aksesuarlar;
create trigger trg_aksesuar_tedarikci_firma_kontrolu
before insert or update of firma_id, tedarikci_id on public.aksesuarlar
for each row execute function public.aksesuar_tedarikci_firma_kontrolu();

alter table public.sistem_ayarlari
  add column if not exists firma_id uuid references public.firmalar(id) on delete cascade,
  add column if not exists tip text,
  add column if not exists guncelleme_tarihi timestamptz default now();

alter table public.sistem_ayarlari drop constraint if exists sistem_ayarlari_anahtar_key;
create unique index if not exists ux_sistem_ayarlari_firma_anahtar
  on public.sistem_ayarlari (firma_id, anahtar);

alter table public.sistem_ayarlari enable row level security;
drop policy if exists "Herkes okuyabilir" on public.sistem_ayarlari;
drop policy if exists "Herkes ekleyebilir" on public.sistem_ayarlari;
drop policy if exists "Herkes güncelleyebilir" on public.sistem_ayarlari;
drop policy if exists "Herkes silebilir" on public.sistem_ayarlari;
drop policy if exists sistem_ayarlari_firma_select on public.sistem_ayarlari;
drop policy if exists sistem_ayarlari_firma_insert on public.sistem_ayarlari;
drop policy if exists sistem_ayarlari_firma_update on public.sistem_ayarlari;

create policy sistem_ayarlari_firma_select on public.sistem_ayarlari
for select using (public.has_firma_access(firma_id));
create policy sistem_ayarlari_firma_insert on public.sistem_ayarlari
for insert with check (public.has_firma_access(firma_id));
create policy sistem_ayarlari_firma_update on public.sistem_ayarlari
for update using (public.has_firma_access(firma_id))
with check (public.has_firma_access(firma_id));
