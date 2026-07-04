-- Needed by the photo upload flow in src/api/my-profile/index.tsx
-- (supabase.storage.from("profiles").upload(...) / .getPublicUrl(...)).
insert into storage.buckets (id, name, public) values ('profiles', 'profiles', true);

create policy "insert_profiles_bucket_authenticated"
on storage.objects for insert to authenticated with check (
    bucket_id = 'profiles'
);
