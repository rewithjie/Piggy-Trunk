# Piggy-Trunk

Flutter admin app backed by Supabase.

## Multi-App Direction (Scaffold Added)

This repository now includes a starter monorepo layout for:

- `apps/admin_web`
- `apps/cashier_web`
- `apps/partner_web`
- `apps/hog_raiser_mobile`
- `packages/shared_models`
- `packages/shared_api`
- `docs/architecture/*`

Start with the architecture docs:

1. `docs/architecture/multi_app_blueprint.md`
2. `docs/architecture/role_access_matrix.md`
3. `docs/architecture/api_contract_v1.md`

Current production/admin code is still in root `lib/`. Move features gradually into `apps/admin_web` and shared logic into `packages/*`.

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
