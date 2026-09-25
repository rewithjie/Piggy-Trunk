---
name: auto-release
description: Builds the Flutter web release, creates a simple commit identifying the edited section, and pushes to git on completed tasks.
---

# Automated Web Release and Git Push

Follow this runbook upon completing code or UI changes in the Piggy-Trunk project:

## Procedure

1. **Build Web Release**:
   Execute the Flutter web release build to generate updated assets in `build/web/`:
   ```powershell
   flutter build web --release
   ```

2. **Commit with Simple Section-Specific Message**:
   - Inspect git diff:
     ```powershell
     git status
     ```
   - Match the user's direct, simple commit message style, clearly stating the section/module edited (e.g. `Update landing hero and download sections`, `Fix admin inventory table`, `Update mobile raiser drawer`).
   - Do NOT use complex conventional commit formatting or lengthy multi-line descriptions.
   - Stage and commit:
     ```powershell
     git add .
     git commit -m "<Simple message mentioning edited section>"
     ```

3. **Push to Remote**:
   Push to the repository branch:
   ```powershell
   git push origin main
   ```

4. **External Actions Rule**:
   If any prerequisite or follow-up lies outside the repository (e.g., Supabase dashboard configuration, Vercel web console settings, DNS records, API credentials), do not act on it automatically. Report it clearly to the user.
