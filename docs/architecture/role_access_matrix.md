# Role Access Matrix

This is the initial permission baseline. Adjust per business policy.

| Feature / Data | admin | cashier | partner | hog_raiser |
|---|---|---|---|---|
| Manage users and role assignment | full | none | none | none |
| View all sales | full | full | summary only | none |
| Create sales / receipts | full | full | none | none |
| Manage inventory products | full | full | read only | none |
| View investment offerings | full | read only | full | none |
| Create/approve investments | full | none | create own | none |
| View partner returns and payouts | full | none | own only | none |
| View hog raiser profile | full | read only | none | own only |
| Update feeding / health logs | full | none | none | own only |
| Update growth and farm tasks | full | none | none | own only |
| Admin dashboard reporting | full | none | none | none |

## Notes

- `partner` and `hog_raiser` should only read/write their own records.
- For any cross-role access, enforce ownership checks in RLS and API code.
