-- These tables have RLS enabled (initial.sql) but had no policies at all,
-- which means "deny everything" by default - useChildren()/useGenders()/etc.
-- were returning nothing. They're read-only lookup/enum tables, so allow
-- select to everyone.
create policy "select_children_public"
on "public"."children"
as permissive
for select
to public
using (true);

create policy "select_family_plans_public"
on "public"."family_plans"
as permissive
for select
to public
using (true);

create policy "select_zodiac_signs_public"
on "public"."zodiac_signs"
as permissive
for select
to public
using (true);

create policy "select_genders_public"
on "public"."genders"
as permissive
for select
to public
using (true);

create policy "select_sexualities_public"
on "public"."sexualities"
as permissive
for select
to public
using (true);

create policy "select_ethnicities_public"
on "public"."ethnicities"
as permissive
for select
to public
using (true);

create policy "select_pronouns_public"
on "public"."pronouns"
as permissive
for select
to public
using (true);

create policy "select_pets_public"
on "public"."pets"
as permissive
for select
to public
using (true);

create policy "select_prompts_public"
on "public"."prompts"
as permissive
for select
to public
using (true);
