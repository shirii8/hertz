select
id,
first_name,
last_name,
dob,
height_cm,
neighbourhood,
latitude,
longitude,
max_distance_km,
min_age,
max_age,
phone
from profiles
left join children on children.id = profiles.children_id
where id = '00000000-0000-0000-0000-000000000000'