-- FISH JOKI: tabel order dan pelacakan status yang aman.
-- Jalankan seluruh file ini sekali di Supabase: SQL Editor > New query > Run.

create table if not exists public.orders (
  id text primary key,
  tracking_token uuid not null unique,
  game text not null check (game in ('fisch', 'fishit')),
  game_name text not null,
  service text not null,
  service_name text not null,
  target text not null,
  username text not null,
  detail text not null default '',
  priority text not null check (priority in ('Normal', 'Express')),
  priority_key text not null check (priority_key in ('normal', 'express')),
  price integer not null check (price >= 0),
  est text not null,
  status smallint not null default 0 check (status between 0 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders enable row level security;

-- Pelanggan hanya dapat membuat order baru; mereka tidak bisa membaca semua order.
create policy "public can create orders"
  on public.orders for insert to anon
  with check (status = 0 and created_at > now() - interval '5 minutes');

-- Status hanya dapat dibaca dengan pasangan Order ID + token pelacakan rahasia.
create or replace function public.get_order_status(p_id text, p_tracking_token uuid)
returns table (
  id text,
  game_name text,
  service_name text,
  target text,
  priority text,
  price integer,
  est text,
  status smallint,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select o.id, o.game_name, o.service_name, o.target, o.priority, o.price,
         o.est, o.status, o.created_at, o.updated_at
  from public.orders o
  where o.id = p_id and o.tracking_token = p_tracking_token;
$$;

grant execute on function public.get_order_status(text, uuid) to anon;
