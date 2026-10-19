-- Already applied on 2026-10-19 under migration
-- t07_guard_daily_goal_sync_when_plan_cascades_on_delete.
-- Allows cascade deletion of own plan without syncing an already-deleted plan.
create or replace function public.t07_sync_daily_goal_from_task()
returns trigger language plpgsql set search_path=public,pg_temp as $$
begin
  if tg_op in ('UPDATE','DELETE') and old.due_date is not null
     and exists(select 1 from public.t07_plans p
       where p.id=old.plan_id and p.user_id=old.user_id)
  then
    perform public.t07_sync_daily_goal_record(old.plan_id,old.due_date);
  end if;
  if tg_op in ('INSERT','UPDATE') and new.due_date is not null
     and exists(select 1 from public.t07_plans p
       where p.id=new.plan_id and p.user_id=new.user_id)
  then
    perform public.t07_sync_daily_goal_record(new.plan_id,new.due_date);
  end if;
  return coalesce(new,old);
end;
$$;

create or replace function public.t07_sync_daily_goals_after_progress_item()
returns trigger language plpgsql set search_path=public,pg_temp as $$
declare
  v_plan_id uuid := coalesce(new.plan_id,old.plan_id);
  d date;
begin
  if exists(select 1 from public.t07_plans p
    where p.id=v_plan_id and p.user_id=auth.uid()) then
    for d in select record_date from public.t07_daily_goal_records
      where plan_id=v_plan_id and user_id=auth.uid()
    loop
      perform public.t07_sync_daily_goal_record(v_plan_id,d);
    end loop;
  end if;
  return coalesce(new,old);
end;
$$;
