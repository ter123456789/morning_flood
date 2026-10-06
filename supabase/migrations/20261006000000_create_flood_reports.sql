-- User-submitted flood situation reports.
-- Run in Supabase Dashboard → SQL Editor, or `supabase db push`.
-- Requires Authentication → Anonymous Sign-ins to be enabled.

create table public.flood_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  water_depth text not null
    check (water_depth in ('none', 'ankle', 'knee', 'waist', 'above_waist')),
  note text check (char_length(note) <= 500),
  created_at timestamptz not null default now()
);

create index flood_reports_created_at_idx
  on public.flood_reports (created_at desc);

alter table public.flood_reports enable row level security;

-- Anonymous users sign in with the `authenticated` role.
create policy "Signed-in users can read reports"
  on public.flood_reports for select
  to authenticated
  using (true);

-- created_at bounds stop clients from back- or future-dating a report.
create policy "Users can insert their own reports"
  on public.flood_reports for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and created_at between now() - interval '5 minutes'
                       and now() + interval '1 minute'
  );

create policy "Users can update their own reports"
  on public.flood_reports for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users can delete their own reports"
  on public.flood_reports for delete
  to authenticated
  using (user_id = auth.uid());

alter publication supabase_realtime add table public.flood_reports;
