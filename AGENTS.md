# Agent Behavior & Workflow Rules

## 1. Automated Web Release & Git Push with Section-Specific Simple Commits
On tasks and sessions where code changes or web updates are made in this repository:
1. **Build Web Release**:
   Execute the release build for Flutter Web to generate updated assets in `build/web/`:
   ```powershell
   flutter build web --release
   ```
2. **Commit Style**:
   - Use simple, direct, concise commit messages that clearly mention which section/part was edited (e.g., `Update landing hero and download sections`, `Fix admin inventory table`, `Update mobile raiser drawer`, `Align admin sidebar active tabs`).
   - Do **NOT** use complex conventional commit prefixes (e.g. `feat:`, `chore:`, `refactor:`) or long multi-line descriptions.
3. **Automatically Stage and Push**:
   - Stage modified files (including `build/web` release artifacts) and push:
     ```powershell
     git add .
     git commit -m "<Simple direct message mentioning the edited section>"
     git push origin main
     ```

## 2. External Actions Policy
- If an action or requirement is outside this codebase or repository (e.g., Supabase dashboard settings, database table creation via SQL editor, third-party provider accounts, DNS/domain records, external service credentials):
  - **Do NOT attempt to act on it.**
  - **Clearly explain and inform the user** what needs to be done so the user can handle it directly.
