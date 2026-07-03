create or replace function update_gender_preferences(
  gender_preferences integer[]
)
returns void
language plpgsql
security definer
as $$
declare
  v_profile_id uuid;
begin

select id into v_profile_id
from profiles where user_id = auth.uid();

if v_profile_id is null then
  raise exception 'profile not found for user %', auth.uid();
end if;

delete from profile_gender_preferences
where profile_id = v_profile_id;

insert into profile_gender_preferences (profile_id, gender_id)
select v_profile_id, unnest(gender_preferences);

end;
$$;
