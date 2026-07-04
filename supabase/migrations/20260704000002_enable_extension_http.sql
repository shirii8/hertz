-- Lets Postgres make outbound HTTP calls (used to talk to Sendbird).
create extension if not exists http with schema extensions;

-- Sendbird app id / api token are read from Vault at call time, not
-- hardcoded here, so they never end up in git history. Create them
-- once per environment (this is NOT part of any migration, run by hand):
--   select vault.create_secret('<your-app-id>', 'sendbird_app_id', 'Sendbird application id');
--   select vault.create_secret('<your-api-token>', 'sendbird_api_token', 'Sendbird api token');

create schema if not exists chat;

-- Creates (or, if channel_url already exists, no-ops on) a Sendbird
-- group channel between two users. `channel` is used as the channel_url
-- so it can be the same id as the interactions row that represents the match.
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

-- chat.* is intentionally NOT granted to anon/authenticated: these functions
-- spend real Sendbird API quota with no internal check on who is calling them,
-- so only service_role (i.e. trusted server-side code) can invoke them.
grant usage on schema chat to service_role;
grant execute on function chat.create_channel(uuid, uuid, uuid) to service_role;
grant execute on function chat.delete_channel(uuid) to service_role;
