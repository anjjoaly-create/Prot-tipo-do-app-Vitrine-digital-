create table if not exists public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  nome text not null,
  telefone text not null,
  tipo text not null check (tipo in ('cliente','fornecedor')),
  endereco text,
  categoria text,
  criado_em timestamptz not null default now()
);

create table if not exists public.produtos (
  id uuid primary key default gen_random_uuid(),
  fornecedor_id uuid not null references public.perfis(id) on delete cascade,
  nome text not null,
  valor numeric(10,2) not null check (valor >= 0),
  imagem_url text,
  criado_em timestamptz not null default now()
);

create index if not exists produtos_fornecedor_idx on public.produtos(fornecedor_id);

alter table public.perfis enable row level security;
alter table public.produtos enable row level security;

drop policy if exists "ver fornecedores e o proprio perfil" on public.perfis;
create policy "ver fornecedores e o proprio perfil" on public.perfis
  for select to authenticated
  using (tipo = 'fornecedor' or id = auth.uid());

drop policy if exists "criar o proprio perfil" on public.perfis;
create policy "criar o proprio perfil" on public.perfis
  for insert to authenticated
  with check (id = auth.uid());

drop policy if exists "editar o proprio perfil" on public.perfis;
create policy "editar o proprio perfil" on public.perfis
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "ver produtos" on public.produtos;
create policy "ver produtos" on public.produtos
  for select to authenticated using (true);

drop policy if exists "criar produtos proprios" on public.produtos;
create policy "criar produtos proprios" on public.produtos
  for insert to authenticated
  with check (fornecedor_id = auth.uid());

drop policy if exists "editar produtos proprios" on public.produtos;
create policy "editar produtos proprios" on public.produtos
  for update to authenticated
  using (fornecedor_id = auth.uid()) with check (fornecedor_id = auth.uid());

drop policy if exists "apagar produtos proprios" on public.produtos;
create policy "apagar produtos proprios" on public.produtos
  for delete to authenticated
  using (fornecedor_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do nothing;

drop policy if exists "fotos: ver" on storage.objects;
create policy "fotos: ver" on storage.objects
  for select using (bucket_id = 'produtos');

drop policy if exists "fotos: enviar na propria pasta" on storage.objects;
create policy "fotos: enviar na propria pasta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'produtos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "fotos: apagar da propria pasta" on storage.objects;
create policy "fotos: apagar da propria pasta" on storage.objects
  for delete to authenticated
  using (bucket_id = 'produtos' and (storage.foldername(name))[1] = auth.uid()::text);
