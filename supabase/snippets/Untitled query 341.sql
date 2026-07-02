
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles(user_id, phone)
  values (new.id, new.phone)
  on conflict (phone)
  do update set user_id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users for each row
execute function handle_new_user();
