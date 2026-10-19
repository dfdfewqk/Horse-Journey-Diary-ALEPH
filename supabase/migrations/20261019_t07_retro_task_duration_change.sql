-- Production schema applied as t07_verified_60_to_120_task_duration_change_between_actual_days_2_and_3
-- Records a verified retrospective change in TASK PLANNED DURATION, not the parent daily_target_minutes.
create table if not exists public.t07_retro_rule_evidence (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 setup_id uuid not null references public.t07_experiment_setup(id) on delete cascade,
 day2_retro_id uuid not null references public.t07_retro_experiment_days(id) on delete restrict,
 day3_retro_id uuid not null references public.t07_retro_experiment_days(id) on delete restrict,
 old_task_id uuid not null references public.t07_tasks(id) on delete restrict,
 new_task_id uuid not null references public.t07_tasks(id) on delete restrict,
 previous_task_planned_minutes integer not null check(previous_task_planned_minutes>0),
 new_task_planned_minutes integer not null check(new_task_planned_minutes>0),
 first_observed_new_plan_at timestamptz not null,
 evidence_type text not null default 'retrospective_task_planned_duration_change'
   check(evidence_type='retrospective_task_planned_duration_change'),
 scope_note text not null,
 reason text not null,
 registered_at timestamptz not null default now(),
 unique(setup_id)
);
alter table public.t07_retro_rule_evidence enable row level security;
revoke all on public.t07_retro_rule_evidence from anon, authenticated;
grant select on public.t07_retro_rule_evidence to authenticated;
do $$
begin
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='t07_retro_rule_evidence'
 and policyname='t07_retro_rule_own_session_select') then
 create policy t07_retro_rule_own_session_select on public.t07_retro_rule_evidence
 for select to authenticated
 using (user_id=(select auth.uid()) and (select private.t07_is_active_session()));
 end if;
end $$;
-- One verified data row added afterwards by source joins on matching owned day2/day3
-- tasks, completed events, and execution records (no copied/hardcoded identifiers).
