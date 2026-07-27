# Multi-App Blueprint

This project can evolve from one Flutter admin app into a multi-client platform.

## Target Clients

1. Root project (`lib/`) - Web/Desktop Admin portal
2. `piggytrunk_mobile` - Unified mobile app (Hog Raiser, Cashier POS, Partner Investor, Admin Mobile)

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
    piggytrunk_mobile/
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
4. Implement dynamic role routing on `piggytrunk_mobile`
5. Implement cashier, partner, and admin UIs within the mobile app.

## Security Rules

- Never expose direct DB credentials in clients
- Gate each API/query by authenticated user role
- Keep RLS enabled and strict by default
- Use server-side validation for sensitive updates (sales, payouts, investments)
