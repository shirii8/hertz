-- Run once per environment (not committed to git, not part of any migration):
-- select vault.create_secret('<your-app-id>', 'sendbird_app_id', 'Sendbird application id');
-- select vault.create_secret('<your-api-token>', 'sendbird_api_token', 'Sendbird api token');

create extension if not exists http with schema extensions;

create schema if not exists chat;

create or replace function chat.create_channel(
  channel uuid,
  user1 uuid,
  user2 uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  sendbird_app_id text;
  sendbird_api_token text;
  sendbird_api_url text;
  sendbird_status int;
  sendbird_content jsonb;
begin
  select decrypted_secret into sendbird_app_id
  from vault.decrypted_secrets
  where name = 'sendbird_app_id';

  select decrypted_secret into sendbird_api_token
  from vault.decrypted_secrets
  where name = 'sendbird_api_token';

  sendbird_api_url := 'https://api-' || sendbird_app_id || '.sendbird.com/v3/group_channels/';

  select status, content::jsonb into sendbird_status, sendbird_content
  from extensions.http((
    'POST',
    sendbird_api_url,
    array[extensions.http_header('Api-Token', sendbird_api_token)],
    'application/json',
    json_build_object(
      'user_ids', array[user1::text, user2::text],
      'channel_url', channel
    )::text
  )::extensions.http_request);

  if sendbird_status != 200 then
    if (sendbird_content->>'code')::int != 400202 then
      raise exception 'sendbird error: %', sendbird_content;
    end if;
  end if;
end;
$$;

create or replace function chat.delete_channel(
  channel uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  sendbird_app_id text;
  sendbird_api_token text;
  sendbird_api_url text;
  sendbird_status int;
  sendbird_content jsonb;
begin
  select decrypted_secret into sendbird_app_id
  from vault.decrypted_secrets
  where name = 'sendbird_app_id';

  select decrypted_secret into sendbird_api_token
  from vault.decrypted_secrets
  where name = 'sendbird_api_token';

  sendbird_api_url := 'https://api-' || sendbird_app_id || '.sendbird.com/v3/group_channels/' || channel;

  select status, content::jsonb into sendbird_status, sendbird_content
  from extensions.http((
    'DELETE',
    sendbird_api_url,
    array[extensions.http_header('Api-Token', sendbird_api_token)],
    'application/json',
    null
  )::extensions.http_request);

  if sendbird_status != 200 then
    raise exception 'sendbird error: %', sendbird_content;
  end if;
end;
$$;

grant usage on schema chat to service_role;
grant execute on function chat.create_channel(uuid, uuid, uuid) to service_role;
grant execute on function chat.delete_channel(uuid) to service_role;

-- manual test sequence:
-- 1. select * from get_profile(5)                -- pick a candidate's id
-- 2. select * from like_profile(candidate_id)     -- returns an interactions.id
-- 3. select * from chat.create_channel(interaction_id, my_profile_id, candidate_id)
-- 4. select * from chat.delete_channel(interaction_id)
