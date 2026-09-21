# Auto Web Release & Git Push Rule

On every task and session where code or web changes are implemented:
1. Run `flutter build web --release` to update production web files under `build/web`.
2. Stage all changed files including `build/web`.
3. Commit using a simple, concise commit message aligned with the user's commit history (no complex semantic tags).
4. Run `git push origin main`.
5. If anything needs to be done outside the repository (Supabase dashboard, Vercel console, external accounts, DNS, etc.), do NOT attempt to perform it automatically — notify and state it clearly to the user.
