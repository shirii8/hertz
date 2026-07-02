-- 1. Enable PostGIS extension so the 'geography' type exists
create extension if not exists postgis;

create or replace function review_profiles()
returns void
language plpgsql
security definer
as $$
declare
  v_actor_id uuid;
  v_loc geography;
  v_max_distance int;
  skip_status int := 1;
  review_status int := 6;
begin

-- 1. Fetch the actor's profile ID, location, and max distance preference
select id, location, max_distance_km 
into v_actor_id, v_loc, v_max_distance
from profiles 
where user_id = auth.uid();

if v_actor_id is null then
  raise exception 'profile not found for user %', auth.uid();
end if;

-- 2. Bulk update skipped interactions back to review status using an optimized JOIN (FROM clause)
update interactions i
set 
  status_id = review_status, 
  updated_at = now()
from profiles p
where i.target_id = p.id
  and i.actor_id = v_actor_id
  and i.status_id = skip_status
  and st_dwithin(p.location, v_loc, v_max_distance * 1000);

end;
$$;