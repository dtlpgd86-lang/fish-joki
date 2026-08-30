create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()); $$;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "public can create orders" on public.orders;
create policy "public can create orders"
on public.orders for insert to anon, authenticated
with check (status = 0 and created_at > now() - interval '5 minutes');

drop policy if exists "admin can read own record" on public.admin_users;
create policy "admin can read own record" on public.admin_users for select to authenticated using (user_id = auth.uid());

drop policy if exists "admins can view orders" on public.orders;
drop policy if exists "admins can update orders" on public.orders;
drop policy if exists "admins can delete orders" on public.orders;
create policy "admins can view orders" on public.orders for select to authenticated using (public.is_admin());
create policy "admins can update orders" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins can delete orders" on public.orders for delete to authenticated using (public.is_admin());

insert into public.admin_users (user_id)
values ('06b09841-97dd-4e93-82fc-8c4ae3ded1a2')
on conflict (user_id) do nothing;
