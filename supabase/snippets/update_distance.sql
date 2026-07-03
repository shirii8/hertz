create or replace function update_distance(
  distance integer
)
returns void
language plpgsql
security definer
as $$
declare
  profile_id uuid;
begin

select id into profile_id
from profiles where user_id = auth.uid();

if profile_id is null then
  raise exception 'profile not found for user %', auth.uid();
end if;

update profiles
set
  max_distance_km = distance,
  updated_at = now()
where id = profile_id;

end;
$$;
