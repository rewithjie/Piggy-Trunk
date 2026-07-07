# create-raiser Supabase Function

This Supabase Edge Function creates a new Hog Raiser account using the service role key.
It performs the following steps:

1. Verifies the calling admin session.
2. Creates a Supabase Auth user for the raiser.
3. Inserts a matching `app_users` row.
4. Inserts a matching `hog_raisers` row.

## Required environment variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`

## Deploy

Use the Supabase CLI to deploy this function:

```bash
supabase functions deploy create-raiser
```

Then configure the required environment variables:

```bash
supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
supabase secrets set SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Usage

Call the function from the admin app using a valid admin session token:

- `POST /functions/v1/create-raiser`
- Authorization header: `Bearer <admin_session_access_token>`
- JSON body: `{ "name": "...", "email": "...", "phone": "...", "address": "...", "lifecycle_stage": "Pre-Starter", "status": "Active" }`
