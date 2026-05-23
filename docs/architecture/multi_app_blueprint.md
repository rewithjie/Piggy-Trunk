# Multi-App Blueprint

This project can evolve from one Flutter admin app into a multi-client platform.

## Target Clients

1. `admin_web` - system management
2. `cashier_web` - point of sale workflow
3. `partner_web` - investor dashboard
4. `hog_raiser_mobile` - raiser task logging and updates

## Shared Platform

All clients should use:

- One Supabase project
- One database schema
- One authentication system
- Role-based authorization for every data operation

## Recommended Repo Layout

```text
piggytrunk/
  apps/
    admin_web/
    cashier_web/
    partner_web/
    hog_raiser_mobile/
  packages/
    shared_models/
    shared_api/
  docs/
    architecture/
  sql/
```

## Implementation Sequence

1. Finalize role matrix and permissions
2. Create shared package interfaces (`shared_models`, `shared_api`)
3. Extract current admin domain logic into shared layers
4. Build `cashier_web` first (fast validation of shared API)
5. Build `partner_web`
6. Build `hog_raiser_mobile`

## Security Rules

- Never expose direct DB credentials in clients
- Gate each API/query by authenticated user role
- Keep RLS enabled and strict by default
- Use server-side validation for sensitive updates (sales, payouts, investments)
