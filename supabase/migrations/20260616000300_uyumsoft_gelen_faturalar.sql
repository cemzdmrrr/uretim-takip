create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create table if not exists public.uyumsoft_entegrasyon_ayarlari (
  id uuid primary key default gen_random_uuid(),
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  aktif boolean not null default false,
  endpoint text,
  kullanici_adi text,
  sifre_secret_ref text,
  son_senkronizasyon_tarihi timestamp with time zone,
  ek_bilgi jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  unique (firma_id)
);

create table if not exists public.uyumsoft_gelen_faturalar (
  id uuid primary key default gen_random_uuid(),
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  kaynak text not null default 'api',
  durum text not null default 'beklemede',
  ettn text not null,
  fatura_no text not null,
  fatura_tarihi timestamp with time zone not null,
  senaryo text,
  cari_unvan text not null,
  vergi_no text,
  vergi_dairesi text,
  fatura_adres text,
  para_birimi text not null default 'TRY',
  ara_toplam_tutar numeric(15, 2) not null default 0,
  kdv_tutari numeric(15, 2) not null default 0,
  toplam_tutar numeric(15, 2) not null default 0,
  tedarikci_id integer references public.tedarikciler(id),
  fatura_id integer references public.faturalar(fatura_id) on delete set null,
  ham_xml text,
  ham_json jsonb not null default '{}'::jsonb,
  onaylayan_user_id uuid references auth.users(id),
  onay_tarihi timestamp with time zone,
  red_sebebi text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint uyumsoft_gelen_faturalar_kaynak_check
    check (kaynak = any (array['api'::text, 'xml'::text])),
  constraint uyumsoft_gelen_faturalar_durum_check
    check (durum = any (array[
      'beklemede'::text,
      'aktarildi'::text,
      'reddedildi'::text,
      'hata'::text
    ]))
);

create table if not exists public.uyumsoft_gelen_fatura_kalemleri (
  id uuid primary key default gen_random_uuid(),
  firma_id uuid not null references public.firmalar(id) on delete cascade,
  gelen_fatura_id uuid not null references public.uyumsoft_gelen_faturalar(id) on delete cascade,
  sira_no integer not null default 1,
  kategori text not null default 'diger',
  urun_kodu text,
  urun_adi text not null,
  aciklama text,
  miktar numeric(15, 4) not null default 0,
  birim text not null default 'adet',
  birim_fiyat numeric(15, 4) not null default 0,
  iskonto_orani numeric(7, 2) not null default 0,
  iskonto_tutari numeric(15, 2) not null default 0,
  kdv_orani numeric(7, 2) not null default 20,
  kdv_tutari numeric(15, 2) not null default 0,
  toplam_tutar numeric(15, 2) not null default 0,
  created_at timestamp with time zone not null default now(),
  constraint uyumsoft_gelen_fatura_kalemleri_kategori_check
    check (kategori = any (array[
      'iplik'::text,
      'aksesuar'::text,
      'fason_uretim'::text,
      'genel_gider'::text,
      'nakliye'::text,
      'personel'::text,
      'diger'::text
    ]))
);

create unique index if not exists idx_uyumsoft_gelen_faturalar_unique
  on public.uyumsoft_gelen_faturalar (firma_id, kaynak, ettn);

create index if not exists idx_uyumsoft_gelen_faturalar_firma_durum
  on public.uyumsoft_gelen_faturalar (firma_id, durum, created_at desc);

create index if not exists idx_uyumsoft_gelen_faturalar_fatura
  on public.uyumsoft_gelen_faturalar (fatura_id);

create index if not exists idx_uyumsoft_gelen_fatura_kalemleri_gelen
  on public.uyumsoft_gelen_fatura_kalemleri (firma_id, gelen_fatura_id, sira_no);

create unique index if not exists idx_faturalar_firma_efatura_uuid_unique
  on public.faturalar (firma_id, efatura_uuid)
  where efatura_uuid is not null;

drop trigger if exists update_uyumsoft_entegrasyon_ayarlari_updated_at
  on public.uyumsoft_entegrasyon_ayarlari;
create trigger update_uyumsoft_entegrasyon_ayarlari_updated_at
  before update on public.uyumsoft_entegrasyon_ayarlari
  for each row execute function update_updated_at_column();

drop trigger if exists update_uyumsoft_gelen_faturalar_updated_at
  on public.uyumsoft_gelen_faturalar;
create trigger update_uyumsoft_gelen_faturalar_updated_at
  before update on public.uyumsoft_gelen_faturalar
  for each row execute function update_updated_at_column();

alter table public.uyumsoft_entegrasyon_ayarlari enable row level security;
alter table public.uyumsoft_gelen_faturalar enable row level security;
alter table public.uyumsoft_gelen_fatura_kalemleri enable row level security;

drop policy if exists "Firma kullanicilari uyumsoft ayarlari gorebilir"
  on public.uyumsoft_entegrasyon_ayarlari;
create policy "Firma kullanicilari uyumsoft ayarlari gorebilir"
  on public.uyumsoft_entegrasyon_ayarlari
  for select using (
    exists (
      select 1 from public.firma_kullanicilari fk
      where fk.firma_id = uyumsoft_entegrasyon_ayarlari.firma_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
    )
  );

drop policy if exists "Adminler uyumsoft ayarlari yonetebilir"
  on public.uyumsoft_entegrasyon_ayarlari;
create policy "Adminler uyumsoft ayarlari yonetebilir"
  on public.uyumsoft_entegrasyon_ayarlari
  for all using (
    exists (
      select 1 from public.firma_kullanicilari fk
      where fk.firma_id = uyumsoft_entegrasyon_ayarlari.firma_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.user_roles ur
      where ur.firma_id = uyumsoft_entegrasyon_ayarlari.firma_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  ) with check (
    exists (
      select 1 from public.firma_kullanicilari fk
      where fk.firma_id = uyumsoft_entegrasyon_ayarlari.firma_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.user_roles ur
      where ur.firma_id = uyumsoft_entegrasyon_ayarlari.firma_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  );

drop policy if exists "Adminler uyumsoft gelen faturalar yonetebilir"
  on public.uyumsoft_gelen_faturalar;
create policy "Adminler uyumsoft gelen faturalar yonetebilir"
  on public.uyumsoft_gelen_faturalar
  for all using (
    exists (
      select 1 from public.firma_kullanicilari fk
      where fk.firma_id = uyumsoft_gelen_faturalar.firma_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.user_roles ur
      where ur.firma_id = uyumsoft_gelen_faturalar.firma_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  ) with check (
    exists (
      select 1 from public.firma_kullanicilari fk
      where fk.firma_id = uyumsoft_gelen_faturalar.firma_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.user_roles ur
      where ur.firma_id = uyumsoft_gelen_faturalar.firma_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  );

drop policy if exists "Adminler uyumsoft gelen fatura kalemleri yonetebilir"
  on public.uyumsoft_gelen_fatura_kalemleri;
create policy "Adminler uyumsoft gelen fatura kalemleri yonetebilir"
  on public.uyumsoft_gelen_fatura_kalemleri
  for all using (
    exists (
      select 1 from public.uyumsoft_gelen_faturalar gf
      join public.firma_kullanicilari fk on fk.firma_id = gf.firma_id
      where gf.id = uyumsoft_gelen_fatura_kalemleri.gelen_fatura_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.uyumsoft_gelen_faturalar gf
      join public.user_roles ur on ur.firma_id = gf.firma_id
      where gf.id = uyumsoft_gelen_fatura_kalemleri.gelen_fatura_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  ) with check (
    exists (
      select 1 from public.uyumsoft_gelen_faturalar gf
      join public.firma_kullanicilari fk on fk.firma_id = gf.firma_id
      where gf.id = uyumsoft_gelen_fatura_kalemleri.gelen_fatura_id
        and fk.user_id = auth.uid()
        and fk.aktif = true
        and fk.rol in ('firma_sahibi', 'firma_admin')
    )
    or exists (
      select 1 from public.uyumsoft_gelen_faturalar gf
      join public.user_roles ur on ur.firma_id = gf.firma_id
      where gf.id = uyumsoft_gelen_fatura_kalemleri.gelen_fatura_id
        and ur.user_id = auth.uid()
        and ur.aktif = true
        and ur.role = 'admin'
    )
  );
