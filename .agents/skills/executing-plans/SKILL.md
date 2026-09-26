---
name: executing-plans
description: Systematically executes a pre-written implementation plan directly in the current session without spawning subagents. Runs verifications/tests per item, commits changes atomically, pauses for developer review, and prepares merge into the target branch. Triggered via /executing-plans or when executing implementation plans.
---

# Superpowers: Executing Plans (Inline / Single-Session Mode)

Execute pre-written implementation plans directly in the current session. 
**Subagents are explicitly disabled.** Antigravity acts as the direct implementer, verifying each task with tests and committing atomically before handing off for developer review.

---

## 🔄 Workflow Lifecycle

```text
[ Existing Plan ]
       ↓
[ Superpowers: executing-plans ]
       ↓
[ Antigravity Implements Task ]
       ↓
[ Runs Verification / Tests ]
       ↓
[ Commits Changes Atomically ]
       ↓ (Repeats for all tasks or pauses at checkpoints)
[ Developer (You) Reviews ]
       ↓
[ Merge Into Target Branch ]
```

---

## 🚫 Critical Constraints & Rules

1. **STRICT NO SUBAGENTS**:
   - **DO NOT** spawn subagents, background worker agents, or secondary reviewer subagents.
   - All tool calls (`replace_file_content`, `run_command`, `write_to_file`) MUST be run directly in the active session.
   - Full conversational context, user preferences, and workspace history remain intact in one thread.

2. **NO MANDATORY GIT WORKTREES**:
   - Work directly in the active repository workspace on the current branch or an agreed feature branch (`git checkout -b feature/...`).
   - Do NOT create separate git worktree directories unless explicitly instructed by the developer.

3. **ATOMIC COMMIT PER PLAN ITEM**:
   - Every completed task that passes verification MUST be committed immediately to Git before starting the next task:
     ```bash
     git add <affected-files>
     git commit -m "feat(scope): descriptive summary of task"
     ```
   - Never combine unrelated tasks into a single monolithic commit.

4. **COMPLIANCE WITH PROJECT RULES (`AGENTS.md`)**:
   - **Frontend (Flutter)**:
     - Strict **NO DROP SHADOWS** (`boxShadow`, `BoxShadow`, `elevation`, `shadows`).
     - Borderless design with clean surface fills (rely on `PulseColors`).
     - Responsive overflow protection down to 280x520 viewports (`Expanded`, `Flexible`, `FittedBox`).
     - Dynamic light/dark theme adaptation.
   - **Backend (Node/TypeScript)**:
     - Mandatory **Jest** for testing in `__tests__/` directories adjacent to code.
     - Explicit error logging in catch blocks (`console.error('[Feature Error]:', err)`).
     - Table indexing on migrations.

---

## 🛠️ Step-by-Step Execution Protocol

### Step 1: Ingest & Audit the Plan
- Read the user's plan completely (formatted per [writing-plans](../writing-plans/SKILL.md) or user-provided in chat/files).
- Verify target files, dependencies, and prerequisites exist.
- If there are ambiguities, plan defects, or missing prerequisites, state them upfront before editing code.

### Step 2: Implement the Task
- Take the first pending task from the plan.
- Implement the required changes cleanly following codebase conventions.

### Step 3: Verify & Test
Immediately run the relevant test or validation command:
- **Mobile (Flutter)**:
  ```bash
  flutter test test/path/to/test.dart
  # Or verify analyzer:
  flutter analyze path/to/file.dart
  ```
- **Backend (TypeScript/Node)**:
  ```bash
  npx jest src/path/to/__tests__/test.test.ts
  # Or check type compilation:
  npx tsc --noEmit
  ```
- If tests fail, investigate root causes and fix them immediately before committing.

### Step 4: Commit the Task
Once verified:
1. Stage the specific files touched by this task.
2. Commit with conventional commit formatting:
   - `feat(...)`: New features or capabilities.
   - `fix(...)`: Bug fixes.
   - `test(...)`: Adding or updating tests.
   - `refactor(...)`: Code refactoring without behavior change.
3. Record the commit hash.

### Step 5: Checkpoint / Developer Review
- If the plan specifies checkpoints (or after completing a logical batch/feature):
  - Pause and present a structured summary:
    - **Tasks Completed**: List of finished items.
    - **Verification Results**: Tests executed and status (Passed / Failed).
    - **Git Commits**: Commit hashes and messages.
    - **Next Step**: Awaiting developer feedback.
- Give the developer the opportunity to review diffs and run the app.

### Step 6: Merge / Final Handoff
Once all tasks are implemented, committed, and approved by the developer:
1. Provide instructions or run the merge into the target branch (e.g., `git merge feature-branch` or prepare PR).
2. Report final clean status.
