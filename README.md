<!-- to bring the changes made in table from sql table editor to migrations folder under supabase - gives sql query list -->

npx supabase db reset

<!-- to check db migrations from sql table editor -->

npx supabase db reset

<!-- to check migrations from sql -->

npx supabase migration list
npx supabase migration list --local

Debugging Note: Profile not found after OTP Verify (Local Supabase)
Symptoms
Verify OTP succeeds
{
"access_token": "...",
"user": {
"id": "56066757-..."
}
}

But calling get_profile() returns

{
"message": "Profile not found for user 56066757-..."
}

or

{
"code":"PGRST303",
"message":"JWT expired"
}
Things to check (in order)
✅ 1. JWT is fresh

Decode the JWT or inspect Verify response.

Check:

user.id

and

JWT

sub

Both must be identical.

Example

user.id = 56066757...
JWT sub = 56066757...
✅ 2. Collection Token

Verify request should automatically save the token.

Post-response Script

var jsonData = pm.response.json();
pm.collectionVariables.set("token", jsonData.access_token);

Collection Authorization

Bearer {{token}}

Requests

Inherit auth from parent
✅ 3. JWT Expired?

If API returns

{
"code":"PGRST303",
"message":"JWT expired"
}

Don't debug SQL.

The request is using an old token.

Generate a fresh OTP.

Verify again.

✅ 4. SQL Function Errors

If Postgres says

column p.neighbourhood does not exist

check schema spelling.

My schema uses

neighbourhood

not

neighbourhood
✅ 5. Does auth.uid() have a profile?

Run

SELECT \*
FROM profiles
WHERE user_id = auth.uid();

or

SELECT \*
FROM profiles
WHERE user_id = '<JWT user id>';

If no rows

↓

No profile is linked to the authenticated user.

✅ 6. Check auth.users
SELECT id, phone
FROM auth.users;

Verify the authenticated user exists.

✅ 7. Check profiles
SELECT
id,
user_id,
first_name
FROM profiles;

Verify

profiles.user_id == auth.users.id
🚨 The mistake that cost me 1 hour

I ran

supabase db reset

but forgot to start my local Supabase stack again.

Because of that,

authentication
database
seeded data
profile linkage

were no longer in the state I expected.

Everything looked like an SQL problem but it wasn't.

Before debugging SQL always check
□ Fresh JWT?
□ JWT saved to collection?
□ JWT not expired?
□ auth.users contains my user?
□ profiles.user_id matches auth.users.id?
□ Local Supabase running?
□ Did I just run db reset?
□ Did I restart Supabase after reset?
Lesson Learned

Never assume it's the SQL function first.

Verify the authentication context (auth.uid()), the JWT, and the local environment before changing database code.
We also unintentionally created a really solid debugging workflow:

Auth → JWT → Headers → Postman Variables → auth.users → profiles → SQL Function → Local Environment
