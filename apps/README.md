# Apps Workspace

Each client app should be isolated here, but connected to shared packages.

- `admin_web`: existing admin portal (migrate current `lib/` here gradually)
- `cashier_web`: POS flow for cashier role
- `partner_web`: investment dashboard for partner role
- `hog_raiser_mobile`: mobile operations for hog raisers

Keep business entities and API client code in `packages/` to avoid duplication.
