-- Applied to production on 2026-10-19 as t07_verified_retroactive_activity_records.
-- Documents schema only, does not insert or backdate user activity.
create table if not exists public.t07_retrospective_activity_days (
 id uuid primary key default gen_random_uuid(),
 setup_id uuid not null references public.t07_experiment_setup(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 activity_date date not null,
 study_minutes integer check (study_minutes is null or study_minutes >= 0),
 completed_task_count integer not null check (completed_task_count > 0),
 other_metric_value numeric,
 other_metric_unit text,
 evidence_sources jsonb not null,
 record_type text not null default 'retrospective_server_verified'
  check (record_type='retrospective_server_verified'),
 registered_at timestamptz not null default now(),
 explanation text not null,
 unique (setup_id,activity_date)
);
alter table public.t07_retrospective_activity_days enable row level security;
revoke all on public.t07_retrospective_activity_days from anon, authenticated;
grant select on public.t07_retrospective_activity_days to authenticated;
do $$
begin
 if not exists (select 1 from pg_policies where schemaname='public'
  and tablename='t07_retrospective_activity_days'
  and policyname='T07 retrospective evidence select own active session') then
  create policy "T07 retrospective evidence select own active session"
   on public.t07_retrospective_activity_days for select to authenticated
   using (user_id=(select auth.uid()) and private.t07_is_active_session());
 end if;
end $$;
