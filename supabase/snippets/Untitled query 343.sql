select
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
row_to_json(children.*)::jsonb as children
from profiles
left join children on children.id = profiles.children_id
where profiles.id = '00000000-0000-0000-0000-000000000000'