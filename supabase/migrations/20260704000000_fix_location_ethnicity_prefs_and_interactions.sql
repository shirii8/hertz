-- Fix schema drift that broke get_profiles(), review_profiles(),
-- update_ethnicity_preferences(), and skip_profile().

-- 1. get_profiles() / review_profiles() reference profiles.location (geography)
--    for st_dwithin() distance filtering, but only latitude/longitude existed.
--    Add a generated geography column kept in sync automatically.
ALTER TABLE public.profiles
  ADD COLUMN location geography(Point, 4326)
  GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED;

CREATE INDEX profiles_location_idx ON public.profiles USING GIST (location);

-- 2. update_ethnicity_preferences() reads/writes profile_ethnicity_preferences,
--    which was never created (only profile_ethnicities, the profile's own
--    ethnicities, existed). Mirror profile_gender_preferences.
CREATE TABLE public.profile_ethnicity_preferences (profile_id uuid NOT NULL, ethnicity_id integer NOT NULL);
ALTER TABLE public.profile_ethnicity_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_ethnicity_preferences ADD CONSTRAINT profile_ethnicity_preferences_pkey PRIMARY KEY (profile_id, ethnicity_id);
ALTER TABLE public.profile_ethnicity_preferences ADD CONSTRAINT profile_ethnicity_preferences_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.profile_ethnicity_preferences ADD CONSTRAINT profile_ethnicity_preferences_ethnicity_id_fkey FOREIGN KEY (ethnicity_id) REFERENCES public.ethnicities(id);
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON public.profile_ethnicity_preferences TO anon;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON public.profile_ethnicity_preferences TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON public.profile_ethnicity_preferences TO service_role;

-- 3. skip_profile() inserts/updates interactions without photo_id/answer_id
--    (skips have no associated photo or answer), but both columns were NOT NULL.
ALTER TABLE public.interactions ALTER COLUMN photo_id DROP NOT NULL;
ALTER TABLE public.interactions ALTER COLUMN answer_id DROP NOT NULL;
