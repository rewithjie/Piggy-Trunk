---
name: auto-release
description: Automatically builds the Flutter web release, creates a simple commit matching the repo history, and pushes to git on every completed task.
---

# Automated Web Release and Git Push

Follow this runbook upon completing code or UI changes in the Piggy-Trunk project:

## Procedure

1. **Build Web Release**:
   Execute the Flutter web release build to generate updated assets in `build/web/`:
   ```powershell
   flutter build web --release
   ```

2. **Commit with Simple Message**:
   - Inspect git diff:
     ```powershell
     git status
     ```
   - Match the user's direct, simple commit message style (e.g. `Update landing hero and download sections`, `Add scroll reveal and card hover animations`).
   - Do NOT use complex conventional commit formatting or lengthy multi-line descriptions.
   - Stage and commit:
     ```powershell
     git add .
     git commit -m "<Simple message>"
     ```

3. **Push to Remote**:
   Push to the repository branch:
   ```powershell
   git push origin main
   ```

4. **External Actions Rule**:
   If any prerequisite or follow-up lies outside the repository (e.g., Supabase dashboard configuration, Vercel web console settings, DNS records, API credentials), do not act on it automatically. Report it clearly to the user.
