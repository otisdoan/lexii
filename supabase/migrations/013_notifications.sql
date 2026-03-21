create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  metadata jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_notifications_recipient_created
  on public.notifications (recipient_user_id, created_at desc);

create index if not exists idx_notifications_unread
  on public.notifications (recipient_user_id, is_read)
  where is_read = false;

alter table public.notifications enable row level security;

drop policy if exists "Users can read own notifications" on public.notifications;
create policy "Users can read own notifications"
  on public.notifications
  for select
  using (auth.uid() = recipient_user_id);

drop policy if exists "Users can insert own notifications" on public.notifications;
create policy "Users can insert own notifications"
  on public.notifications
  for insert
  with check (auth.uid() = recipient_user_id);

drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications"
  on public.notifications
  for update
  using (auth.uid() = recipient_user_id)
  with check (auth.uid() = recipient_user_id);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;