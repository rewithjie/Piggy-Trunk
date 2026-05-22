# Piggy-Trunk

Flutter admin app backed by Supabase.

## Database Setup (Supabase)

1. Create a Supabase project.
2. Open `SQL Editor` in Supabase.
3. Run [`sql/2026-05-22_full_database_setup.sql`](sql/2026-05-22_full_database_setup.sql).
4. In `Authentication > Providers`, enable at least one sign-in method you will use for admins.
5. Create at least one authenticated admin user (Auth Users).

The script creates:
- `public.hog_raisers`
- `public.inventory_products`
- `public.investments`
- Storage buckets: `product-images`, `profile_pictures`
- RLS policies for authenticated access
- Starter seed data for hog raisers and inventory

## App Environment Setup

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Then run:

```bash
flutter pub get
flutter run
```

## Existing Migration Files

- `sql/2026-05-20_add_lifecycle_stage_to_hog_raisers.sql` is a focused patch for lifecycle stage.
- `sql/2026-05-22_hog_raisers_schema_and_seed.sql` handles only the `hog_raisers` table.
- `sql/2026-05-22_full_database_setup.sql` is the complete setup for a fresh environment.
