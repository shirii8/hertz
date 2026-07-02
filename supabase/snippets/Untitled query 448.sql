create or replace function get_profile()
return table()
language plpgsql
security defineras $$
begin
return query
end;
$$

SELECT
    profiles.id,
    profiles.first_name,
    profiles.last_name,
    profiles.dob,
    profiles.height_cm,
    profiles.neighbourhood,
    profiles.latitude,
    profiles.longitude,
    profiles.max_distance_km,
    profiles.min_age,
    profiles.max_age,
    profiles.phone,
    row_to_json(children.*)::jsonb AS children,
    row_to_json(family_plans.*)::jsonb AS family_plan,
    row_to_json(zodiac_signs.*)::jsonb AS zodiac_sign,
    row_to_json(sexualities.*)::jsonb AS sexuality,
    json_build_object(
        'id', genders.id,
        'name', genders.name
    )::jsonb AS gender,
(
SELECT COALESCE(jsonb_agg(json_build_object('id;, genders.id, 'name', genders.plural_name)), '[]'::jsonb)
FROM profile_gender
LEFT JOIN gender
    ON gender.id = profile_gender_preferences.gender_id
WHERE profile_gender.profile_id = '00000000-0000-0000-0000-000000000000'
) as ethnicity_preferences,
(
SELECT COALESCE(jsonb_agg(ethnicities.*), '[]'::jsonb)
FROM profile_ethnicities
LEFT JOIN ethnicities
    ON ethnicities.id = profile_ethnicities.ethnicity_id
WHERE profile_ethnicities.profile_id = '00000000-0000-0000-0000-000000000000'
) as gender_preferences,
(
    select coalesce(jsonb_agg(json_build_object(
    'id', profile_answers.id,
    'answer_text', profile_answers.answer_text,
    'answer_order', profile_answers.answer_order,
    'prompt_id', profile_answers.prompt_id,
    'question', prompts.question
    )order by profile_answers.answer_order), '[]'::jsonb)
    from profile_answers
    left join prompts on prompts.id = profile_answers.prompt_id
where profile_answers.profile_id = '00000000-0000-0000-0000-000000000000' and profile_answers.is_active = true
) as answers,
(
    select coalesce(jsonb_agg(json_build_object(
    'id', profile_photos.id,
    'photo_url', profile_photos.photo_url,
    'photo_order', profile_photos.photo_order
) order by profile_photos.photo_order), '[]'::jsonb)
    from profile_photos
where profile_photos.profile_id = profiles.id and profile_photos.is_active = true
) as photos,
(
    select photo_url
    from profile_photoswehre profile_photos.profile_id = profiles.id and profile_photos.is_active=true
    order by profile_photos.photo_order
    limit 1
) as avatar_url
FROM profiles
LEFT JOIN children
    ON children.id = profiles.children_id
LEFT JOIN family_plans
    ON family_plans.id = profiles.family_plan_id
LEFT JOIN zodiac_signs
    ON zodiac_signs.id = profiles.zodiac_sign_id
LEFT JOIN sexualities
    ON sexualities.id = profiles.sexuality_id
LEFT JOIN genders
    ON genders.id = profiles.gender_id
WHERE profiles.id = '00000000-0000-0000-0000-000000000000';

-- select ethnicities.*
-- from profile_ethnicities
-- left join ethnicities on ethnicities.id = profile_ethnicities.ethnicity_id
-- where profile_ethnicities.profile_id='00000000-0000-0000-0000-000000000000'

-- select json_agg(ethnicities.*)
-- from profile_ethnicities
-- left join ethnicities on ethnicities.id = profile_ethnicities.ethnicity_id
-- where profile_ethnicities.profile_id='00000000-0000-0000-0000-000000000000'

-- SELECT COALESCE(jsonb_agg(ethnicities.*), '[]'::jsonb)
-- FROM profile_ethnicities
-- LEFT JOIN ethnicities
--     ON ethnicities.id = profile_ethnicities.ethnicity_id
-- WHERE profile_ethnicities.profile_id = '00000000-0000-0000-0000-000000000000';

-- select coalesce(jsonb_agg(json_build_object(
--     'id', profile_answers.id,
--     'answer_text', profile_answers.answer_text,
--     'answer_order', profile_answers.answer_order,
--     'prompt_id', profile_answers.prompt_id,
--     'question', prompts.question
-- )order by profile_answers.answer_order), '[]'::jsonb)
-- from profile_answers
-- left join prompts on prompts.id = profile_answers.prompt_id
-- where profile_answers.profile_id = '00000000-0000-0000-0000-000000000000' and profile_answers.is_active = true