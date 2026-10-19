-- Applied production migration: t07_audited_five_day_experiment_retro_registration
-- No backdating or modification of contemporaneous Day observations.
create table if not exists public.t07_retro_experiment_days (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 setup_id uuid not null references public.t07_experiment_setup(id) on delete cascade,
 source_activity_id uuid not null references public.t07_retrospective_activity_days(id) on delete restrict,
 day_number integer not null check(day_number between 1 and 5),
 activity_date date not null,
 metric_value_minutes numeric not null check(metric_value_minutes>=0),
 metric_missing boolean not null default false,
 other_metric_value numeric,other_metric_unit text,
 completed_task_count integer not null check(completed_task_count>0),
 method_note text not null,
 registration_kind text not null default 'assisted_retrospective_from_verified_server_logs'
   check(registration_kind='assisted_retrospective_from_verified_server_logs'),
 registered_at timestamptz not null default now(),
 unique(setup_id,day_number),unique(setup_id,activity_date),unique(source_activity_id)
);
alter table public.t07_retro_experiment_days enable row level security;
revoke all on public.t07_retro_experiment_days from anon,authenticated;
grant select on public.t07_retro_experiment_days to authenticated;
do $$ begin
 if not exists(select 1 from pg_policies where schemaname='public' and
 tablename='t07_retro_experiment_days' and policyname='t07_retro_experiment_select_own_active') then
   create policy t07_retro_experiment_select_own_active on public.t07_retro_experiment_days
   for select to authenticated
   using(user_id=(select auth.uid()) and (select private.t07_is_active_session()));
 end if;
end $$;
create or replace function public.t07_register_verified_retro_experiment()
returns integer language plpgsql security definer set search_path=public,private,auth,pg_temp
as $body$
declare v_user uuid:=auth.uid();v_setup public.t07_experiment_setup%rowtype;
 v_n integer;v_min date;v_max date;v_rows integer;
begin
 if v_user is null or not private.t07_is_active_session() then
   raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select * into v_setup from public.t07_experiment_setup where user_id=v_user for update;
 if not found then raise exception 'EXPERIMENT_SETUP_REQUIRED'; end if;
 select count(*),min(activity_date),max(activity_date) into v_n,v_min,v_max
 from public.t07_retrospective_activity_days where user_id=v_user and setup_id=v_setup.id;
 if v_n<>5 or v_max-v_min<>4 or v_min<(v_setup.created_at at time zone 'Asia/Seoul')::date then
   raise exception 'FIVE_VERIFIED_CONSECUTIVE_DAYS_REQUIRED';end if;
 if exists(select 1 from public.t07_retrospective_activity_days r where
 r.user_id=v_user and r.setup_id=v_setup.id and
 (r.completed_task_count<1 or not exists(select 1 from public.t07_completion_events e
 where e.user_id=v_user and (e.completed_at at time zone 'Asia/Seoul')::date=r.activity_date)))
 then raise exception 'SOURCE_ACTIVITY_NOT_VERIFIED';end if;
 insert into public.t07_retro_experiment_days
 (user_id,setup_id,source_activity_id,day_number,activity_date,metric_value_minutes,
 metric_missing,other_metric_value,other_metric_unit,completed_task_count,method_note)
 select v_user,v_setup.id,r.id,row_number() over(order by r.activity_date)::integer,r.activity_date,
 coalesce(r.study_minutes,0),r.study_minutes is null,r.other_metric_value,r.other_metric_unit,
 r.completed_task_count,
 case when r.study_minutes is null and r.other_metric_value is not null then
 '공부 시간 미측정: 누락값 규칙으로 0분; 별도 문제 목표 달성만 확인'
 when r.evidence_sources::text like '%"raw_count": 2%' then
 '동일 작업·시작시각 중복 의심 2건을 한 세션으로 계산'
 else '서버 실제 활동에 근거한 사후 등록' end
 from public.t07_retrospective_activity_days r where r.user_id=v_user and r.setup_id=v_setup.id
 order by r.activity_date on conflict(setup_id,day_number) do nothing;
 select count(*) into v_rows from public.t07_retro_experiment_days
 where user_id=v_user and setup_id=v_setup.id;
 if v_rows<>5 then raise exception 'RETROSPECTIVE_REGISTRATION_INCOMPLETE';end if;
 return v_rows;
end;
$body$;
revoke all on function public.t07_register_verified_retro_experiment() from public,anon;
grant execute on function public.t07_register_verified_retro_experiment() to authenticated;
