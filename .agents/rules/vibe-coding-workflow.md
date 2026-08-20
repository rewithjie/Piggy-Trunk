# Vibe Coding Workflow & Planning Rules

This workspace enforces a strict **Plan-First Architecture & Vibe Coding Workflow** for all development and revision tasks.

---

## Core Rules for the AI Assistant

### 1. Mandatory Planning Before Coding
- **Never modify or create code files immediately** upon receiving a feature request, bug fix, or revision task.
- First, thoroughly inspect and read the relevant database schemas (SQL), models, widgets, and services.
- Always generate an **`implementation_plan.md`** outlining:
  - Background context & user intent
  - Specific files to modify, create, or delete
  - Proposed changes & data flow logic
  - Step-by-step execution roadmap
  - Verification & testing plan

### 2. Wait for Explicit User Approval
- Present the implementation plan to the user.
- **STOP and wait** for the user's explicit go-signal (e.g., "Go", "Proceed", "Approved") before executing any file edits or commands.
- If the user requests adjustments to the plan, update the plan first.

### 3. Micro-Batch & Modular Execution
- Execute changes step-by-step (e.g., SQL/Backend -> Data Models/Providers -> UI Components/Forms -> Polish).
- Ensure existing state management, models, and UI conventions are preserved.

### 4. Verification & Clean Code
- After implementing changes, verify that the code compiles without syntax or lint errors.
- Summarize the accomplishments in a walkthrough or response.
