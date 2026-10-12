-- T07 security core (applied to Supabase project pds-diary-t06)
-- Requires the t07_* tables created by the earlier parallel-store migration.
-- No secret values are stored in this file.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

create or replace function private.t07_is_active_session()
returns boolean
language sql
stable
security definer
set search_path = auth, public, private
as $
  select
    auth.uid() is not null
    and nullif(auth.jwt()->>'session_id','') is not null
    and exists (
      select 1
      from auth.sessions s
      where s.id = (auth.jwt()->>'session_id')::uuid
        and s.user_id = auth.uid()
        and (s.not_after is null or s.not_after > now())
    );
$;

revoke all on function private.t07_is_active_session() from public, anon;
grant execute on function private.t07_is_active_session() to authenticated, service_role;

create or replace function public.t07_session_status()
returns boolean
language sql
stable
security invoker
set search_path = public, private
as $
  select private.t07_is_active_session();
$;

revoke all on function public.t07_session_status() from public, anon;
grant execute on function public.t07_session_status() to authenticated;

create or replace function public.t07_enforce_owner()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    if current_user in ('postgres','service_role','supabase_admin') then
      return new;
    end if;
    raise exception 'AUTH_REQUIRED' using errcode='42501';
  end if;

  if tg_op = 'INSERT' then
    new.user_id := v_uid;
  elsif tg_op = 'UPDATE' then
    if old.user_id is distinct from v_uid then
      raise exception 'OWNER_MISMATCH' using errcode='42501';
    end if;
    new.user_id := old.user_id;
  end if;

  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    't07_plans','t07_plan_history','t07_plan_progress_items','t07_tasks',
    't07_execution_records','t07_completion_events','t07_reflections',
    't07_task_reflections','t07_important_dates','t07_daily_goal_records',
    't07_experiment_setup','t07_daily_observations','t07_rule_changes',
    't07_claim_requests'
  ]
  loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on table public.%I from anon',t);
    execute format('grant select,insert,update,delete on table public.%I to authenticated',t);
  end loop;
end $$;

-- Representative owner policy. The live DB contains the same four policies
-- (SELECT / INSERT / UPDATE / DELETE) on every T07 user table.
-- Example:
-- create policy t07_plans_select_own on public.t07_plans
-- for select to authenticated
-- using (user_id = auth.uid() and private.t07_is_active_session());

create or replace function public.t07_record_today_observation()
returns public.t07_daily_observations
language plpgsql
security invoker
set search_path=public,pg_temp
as $$
declare
  v_uid uuid:=auth.uid();
  v_today date:=(now() at time zone 'Asia/Seoul')::date;
  v_setup public.t07_experiment_setup%rowtype;
  v_day integer;
  v_value numeric:=0;
  v_result public.t07_daily_observations%rowtype;
begin
  if v_uid is null or not private.t07_is_active_session() then
    raise exception 'AUTH_REQUIRED' using errcode='42501';
  end if;

  select * into v_setup
  from public.t07_experiment_setup
  where user_id=v_uid;

  if not found then
    raise exception 'EXPERIMENT_SETUP_REQUIRED';
  end if;

  select count(*)+1 into v_day
  from public.t07_daily_observations
  where user_id=v_uid;

  if v_day>5 then
    raise exception 'FIVE_DAYS_ALREADY_COMPLETE';
  end if;

  if v_day=3 and not exists(
    select 1 from public.t07_rule_changes where user_id=v_uid
  ) then
    raise exception 'RULE_CHANGE_REQUIRED_BEFORE_DAY3';
  end if;

  if exists(
    select 1 from public.t07_daily_observations
    where user_id=v_uid and observation_date=v_today
  ) then
    raise exception 'TODAY_ALREADY_RECORDED';
  end if;

  select coalesce(sum(er.actual_minutes),0)
  into v_value
  from public.t07_execution_records er
  join public.t07_tasks t on t.id=er.task_id
  where er.user_id=v_uid
    and t.user_id=v_uid
    and t.plan_id=v_setup.plan_id
    and (er.started_at at time zone 'Asia/Seoul')::date=v_today;

  insert into public.t07_daily_observations(
    user_id,day_number,observation_date,metric_value,note
  )
  values(
    v_uid,v_day,v_today,v_value,
    case when v_value=0
      then '선택한 목표의 실행 기록이 없어 누락값 규칙에 따라 0분'
      else '선택한 목표의 실행 기록 actual_minutes를 서버에서 합산'
    end
  )
  returning * into v_result;

  return v_result;
end;
$$;

revoke all on function public.t07_record_today_observation() from public, anon;
grant execute on function public.t07_record_today_observation() to authenticated;

-- The live database also contains:
-- t07_complete_task(uuid)
-- t07_cancel_task_completion(uuid)
-- t07_sync_daily_goal_record(uuid,date)
-- t07_apply_rule_change(integer,text)
-- Each validates auth.uid(), active session, and owner before changing protected data.
