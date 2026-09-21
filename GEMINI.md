# Agent Behavior & Workflow Rules

## 1. Automated Web Release & Git Push on Every Task
On every task and session where code changes or web updates are made in this repository:
1. **Build Web Release**:
   Always run the release build for Flutter Web:
   ```powershell
   flutter build web --release
   ```
2. **Commit Style**:
   - Align commit messages directly with the user's commit history style.
   - Use simple, direct, concise commit messages (e.g., `Update landing hero and download sections`, `Add scroll reveal and card hover animations`, `Fix table styling`, `Update inventory screen`).
   - Do **NOT** use complex, verbose conventional commit prefixes or semantic commit structures.
3. **Automatically Stage and Push**:
   - Stage the modified files, including updated `build/web` release artifacts:
     ```powershell
     git add .
     git commit -m "<Simple direct message>"
     git push origin main
     ```

## 2. External Actions Policy
- If an action or requirement is outside this codebase or repository (e.g., Supabase dashboard settings, database table creation via SQL editor, third-party provider accounts, DNS/domain records, external service credentials):
  - **Do NOT attempt to act on it.**
  - **Clearly explain and inform the user** what needs to be done so the user can handle it directly.
