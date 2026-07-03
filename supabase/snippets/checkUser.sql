create or replace function "checkUser"()
returns boolean
language plpgsql
security definer
stable
as $$
declare
  v_first_name text;
  v_dob date;
begin
  select first_name, dob into v_first_name, v_dob
  from profiles
  where user_id = auth.uid();

  return v_first_name is not null and v_dob is not null;
end;
$$;
