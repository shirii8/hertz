CREATE OR REPLACE FUNCTION public.get_profile(page_size integer)
 RETURNS TABLE(
   id uuid, 
   first_name text, 
   age integer, 
   height_cm integer, 
   neighbourhood text,
   children text, 
   family_plan text, 
   zodiac_sign text, 
   gender text, 
   sexuality text, 
   ethnicities text[], 
   pets text[], 
   pronouns text[], 
   photos jsonb, 
   answers jsonb
)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_profile_id UUID;
  current_profile profiles%ROWTYPE;

  like_status INT := 2;
  match_status INT := 4;
  unmatch_status INT := 5;
  review_status INT := 6;
BEGIN

-- Get current user's profile ID
SELECT p.id
INTO v_profile_id
FROM profiles p
WHERE p.user_id = auth.uid();

  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Profile not found for user %', auth.uid();
  END IF;

  -- Get current profile row
  SELECT *
  INTO current_profile
  FROM profiles p
  WHERE p.id = v_profile_id;

  RETURN QUERY
  WITH filtered_profiles AS (
    SELECT p.*
    FROM profiles p
    WHERE p.id <> v_profile_id
      AND EXTRACT(YEAR FROM AGE(p.dob))
            BETWEEN current_profile.min_age AND current_profile.max_age
      AND EXTRACT(YEAR FROM AGE(current_profile.dob))
            BETWEEN p.min_age AND p.max_age
  )
  SELECT
      p.id,
      p.first_name,
      EXTRACT(YEAR FROM AGE(p.dob))::INT AS age,
      p.height_cm,
      p.neighbourhood, 

      children.name AS children,
      family_plans.name AS family_plan,
      zodiac_signs.name AS zodiac_sign,
      genders.name AS gender,
      sexualities.name AS sexuality,

      (
        SELECT COALESCE(
          ARRAY_AGG(e.name),
          ARRAY[]::TEXT[]
        )
        FROM profile_ethnicities pe
        JOIN ethnicities e ON e.id = pe.ethnicity_id
        WHERE pe.profile_id = p.id
      ) AS ethnicities,

      (
        SELECT COALESCE(
          ARRAY_AGG(pt.name),
          ARRAY[]::TEXT[]
        )
        FROM profile_pets pp
        JOIN pets pt ON pt.id = pp.pet_id
        WHERE pp.profile_id = p.id
      ) AS pets,

      (
        SELECT COALESCE(
          ARRAY_AGG(pr.name),
          ARRAY[]::TEXT[]
        )
        FROM profile_pronouns pp
        JOIN pronouns pr ON pr.id = pp.pronoun_id
        WHERE pp.profile_id = p.id
      ) AS pronouns,

      (
        SELECT COALESCE(
          JSONB_AGG(
            JSONB_BUILD_OBJECT(
              'id', ph.id,
              'photo_url', ph.photo_url,
              'photo_order', ph.photo_order
            )
            ORDER BY ph.photo_order
          ),
          '[]'::JSONB
        )
        FROM profile_photos ph
        WHERE ph.profile_id = p.id
          AND ph.is_active = TRUE
      ) AS photos,

      (
        SELECT COALESCE(
          JSONB_AGG(
            JSONB_BUILD_OBJECT(
              'id', pa.id,
              'answer_text', pa.answer_text,
              'answer_order', pa.answer_order,
              'question', pr.question
            )
            ORDER BY pa.answer_order
          ),
          '[]'::JSONB
        )
        FROM profile_answers pa
        JOIN prompts pr ON pr.id = pa.prompt_id
        WHERE pa.profile_id = p.id
          AND pa.is_active = TRUE
      ) AS answers

  FROM filtered_profiles p
  LEFT JOIN children ON children.id = p.children_id
  LEFT JOIN family_plans ON family_plans.id = p.family_plan_id
  LEFT JOIN zodiac_signs ON zodiac_signs.id = p.zodiac_sign_id
  LEFT JOIN genders ON genders.id = p.gender_id
  LEFT JOIN sexualities ON sexualities.id = p.sexuality_id
  LEFT JOIN interactions i_cp ON i_cp.target_id = p.id AND i_cp.actor_id = v_profile_id
  LEFT JOIN interactions i_p ON i_p.target_id = v_profile_id AND i_p.actor_id = p.id
  WHERE
    (
      NOT EXISTS (
        SELECT 1 FROM profile_gender_preferences pg WHERE pg.profile_id = v_profile_id
      )
      OR EXISTS (
        SELECT 1 FROM profile_gender_preferences pg WHERE pg.profile_id = v_profile_id AND pg.gender_id = p.gender_id
      )
    )
    AND
    (
      NOT EXISTS (
        SELECT 1 FROM profile_gender_preferences pg WHERE pg.profile_id = p.id
      )
      OR EXISTS (
        SELECT 1 FROM profile_gender_preferences pg WHERE pg.profile_id = p.id AND pg.gender_id = current_profile.gender_id
      )
    )
    AND (
      i_cp.status_id IS NULL OR i_cp.status_id IN (review_status, unmatch_status)
    )
    AND (
      i_p.status_id IS NULL OR i_p.status_id NOT IN (like_status, match_status)
    )
  LIMIT get_profile.page_size;

END;
$function$;