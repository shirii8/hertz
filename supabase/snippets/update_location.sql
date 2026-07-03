create or replace function update_location(
  latitude float8,
  longitude float8,
  neighbourhood text
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
  latitude = update_location.latitude,
  longitude = update_location.longitude,
  neighbourhood = update_location.neighbourhood,
  updated_at = now()
where id = profile_id;

end;
$$;
