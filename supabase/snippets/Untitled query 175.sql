select
    proname,
    pronamespace::regnamespace,
    proargnames
from pg_proc
where proname = 'get_profile';