CREATE OR REPLACE FUNCTION public.update_profile(
  first_name text default null,
  last_name text default null,
  dob date default null,
  height_cm integer default null,
  neighborhood text default null,
  latitude float8 default null,
  longitude float8 default null,
  children integer default null,
  family_plan integer default null,
  zodiac_sign integer default null,
  sexuality integer default null,
  gender integer default null,
  ethnicities integer[] default null,
  pets integer[] default null,
  pronouns integer[] default null,
  gender_preferences integer[] default null,
  answers jsonb default null,
  photos jsonb default null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile_id uuid;
  answer jsonb;
  existing_answer record;
  new_answer_id uuid;
  active_answer_ids uuid[] := '{}';
  photo jsonb;
  existing_photo record;
  new_photo_id uuid;
  active_photo_ids uuid[] := '{}';
BEGIN
  SELECT profiles.id INTO v_profile_id
  FROM profiles WHERE user_id = auth.uid();

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'profile not found for user %', auth.uid();
  END IF;

  UPDATE profiles
  SET
    first_name = coalesce(update_profile.first_name, profiles.first_name),
    last_name = update_profile.last_name,
    dob = coalesce(update_profile.dob, profiles.dob),
    height_cm = coalesce(update_profile.height_cm, profiles.height_cm),
    neighborhood = coalesce(update_profile.neighborhood, profiles.neighborhood),
    latitude = coalesce(update_profile.latitude, profiles.latitude),
    longitude = coalesce(update_profile.longitude, profiles.longitude),
    children_id = coalesce(update_profile.children, profiles.children_id),
    family_plan_id = coalesce(update_profile.family_plan, profiles.family_plan_id),
    zodiac_sign_id = coalesce(update_profile.zodiac_sign, profiles.zodiac_sign_id),
    sexuality_id = coalesce(update_profile.sexuality, profiles.sexuality_id),
    gender_id = coalesce(update_profile.gender, profiles.gender_id),
    updated_at = now()
  WHERE id = v_profile_id;

  IF ethnicities IS NOT NULL THEN
    DELETE FROM profile_ethnicities WHERE profile_id = v_profile_id;
    INSERT INTO profile_ethnicities (profile_id, ethnicity_id) SELECT v_profile_id, unnest(ethnicities);
  END IF;

  IF pets IS NOT NULL THEN
    DELETE FROM profile_pets WHERE profile_id = v_profile_id;
    INSERT INTO profile_pets (profile_id, pet_id) SELECT v_profile_id, unnest(pets);
  END IF;

  IF pronouns IS NOT NULL THEN
    DELETE FROM profile_pronouns WHERE profile_id = v_profile_id;
    INSERT INTO profile_pronouns (profile_id, pronoun_id) SELECT v_profile_id, unnest(pronouns);
  END IF;

  IF gender_preferences IS NOT NULL THEN
    DELETE FROM profile_gender_preferences WHERE profile_id = v_profile_id;
    INSERT INTO profile_gender_preferences (profile_id, gender_id) SELECT v_profile_id, unnest(gender_preferences);
  END IF;

  IF answers IS NOT NULL THEN
    FOR answer IN (SELECT * FROM jsonb_array_elements(update_profile.answers)) LOOP
      IF answer->>'id' IS NOT NULL THEN
        SELECT id, answer_text, prompt_id, is_active INTO existing_answer
        FROM profile_answers WHERE id = (answer->>'id')::uuid AND profile_id = v_profile_id;
        IF found THEN
          IF existing_answer.answer_text IS DISTINCT FROM (answer->>'answer_text') OR existing_answer.prompt_id IS DISTINCT FROM (answer->>'prompt_id')::integer THEN
            UPDATE profile_answers SET is_active = false WHERE id = existing_answer.id;
            new_answer_id := gen_random_uuid();
            INSERT INTO profile_answers (id, profile_id, answer_text, prompt_id, answer_order, is_active)
            VALUES (new_answer_id, v_profile_id, (answer->>'answer_text'), (answer->>'prompt_id')::integer, (answer->>'answer_order')::integer, true);
            active_answer_ids := array_append(active_answer_ids, new_answer_id);
          ELSE
            UPDATE profile_answers SET is_active = true, answer_order = (answer->>'answer_order')::integer WHERE id = existing_answer.id;
            active_answer_ids := array_append(active_answer_ids, existing_answer.id);
          END IF;
        END IF;
      ELSE
        new_answer_id := gen_random_uuid();
        INSERT INTO profile_answers (id, profile_id, answer_text, prompt_id, answer_order, is_active)
        VALUES (new_answer_id, v_profile_id, (answer->>'answer_text'), (answer->>'prompt_id')::integer, (answer->>'answer_order')::integer, true);
        active_answer_ids := array_append(active_answer_ids, new_answer_id);
      END IF;
    END LOOP;
    IF jsonb_array_length(update_profile.answers) = 0 THEN
      UPDATE profile_answers SET is_active = false WHERE profile_id = v_profile_id AND is_active = true;
    ELSE
      UPDATE profile_answers SET is_active = false WHERE profile_id = v_profile_id AND is_active = true AND id <> ALL (active_answer_ids);
    END IF;
  END IF;

  IF photos IS NOT NULL THEN
    FOR photo IN (SELECT * FROM jsonb_array_elements(update_profile.photos)) LOOP
      IF photo->>'id' IS NOT NULL THEN
        SELECT id, photo_url, is_active INTO existing_photo
        FROM profile_photos WHERE id = (photo->>'id')::uuid AND profile_id = v_profile_id;
        IF found THEN
          IF existing_photo.photo_url IS DISTINCT FROM (photo->>'photo_url') THEN
            UPDATE profile_photos SET is_active = false WHERE id = existing_photo.id;
            new_photo_id := gen_random_uuid();
            INSERT INTO profile_photos (id, profile_id, photo_url, photo_order, is_active)
            VALUES (new_photo_id, v_profile_id, (photo->>'photo_url'), (photo->>'photo_order')::integer, true);
            active_photo_ids := array_append(active_photo_ids, new_photo_id);
          ELSE
            UPDATE profile_photos SET is_active = true, photo_order = (photo->>'photo_order')::integer WHERE id = existing_photo.id;
            active_photo_ids := array_append(active_photo_ids, existing_photo.id);
          END IF;
        END IF;
      ELSE
        new_photo_id := gen_random_uuid();
        INSERT INTO profile_photos (id, profile_id, photo_url, photo_order, is_active)
        VALUES (new_photo_id, v_profile_id, (photo->>'photo_url'), (photo->>'photo_order')::integer, true);
        active_photo_ids := array_append(active_photo_ids, new_photo_id);
      END IF;
    END LOOP;
    IF jsonb_array_length(update_profile.photos) = 0 THEN
      UPDATE profile_photos SET is_active = false WHERE profile_id = v_profile_id AND is_active = true;
    ELSE
      UPDATE profile_photos SET is_active = false WHERE profile_id = v_profile_id AND is_active = true AND id <> ALL (active_photo_ids);
    END IF;
  END IF;
END;
$$;