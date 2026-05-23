# admin_web

This folder is reserved for the web admin client.

Current admin implementation still lives in the root Flutter app.
Recommended migration path:

1. Move reusable models/services into `packages/shared_models` and `packages/shared_api`
2. Copy admin-specific screens/providers into this app
3. Keep feature parity before removing root admin code
