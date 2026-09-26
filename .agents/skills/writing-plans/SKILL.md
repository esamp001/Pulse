---
name: writing-plans
description: Creates detailed, testable, bite-sized implementation plans ready for direct execution via executing-plans. Formats tasks with exact files, TDD steps, verification commands, and atomic commits. Triggered via /writing-plans or /plan.
---

# Superpowers: Writing Plans

Use when planning a multi-step feature, bugfix, or refactor before touching code.
Produces bite-sized, testable tasks that feed directly into **`executing-plans`**.

---

## 🎯 Core Principles

1. **Bite-Sized Tasks (2–5 minutes each)**: Each task is small enough to hold easily in context and test independently.
2. **Explicit Interfaces & Files**: Specify exact file paths, class/function signatures, and data structures.
3. **Test-Driven & Verification-First**: Every task must have an exact verification command (Jest for backend, Flutter test for mobile).
4. **Atomic Commit per Task**: Every task defines its exact conventional Git commit message (`feat(...)`, `fix(...)`, `test(...)`).
5. **Direct Alignment with `executing-plans`**: The plan structure must be 100% executable by Antigravity in inline single-session mode (no subagents).

---

## 📋 Standard Plan Template

When writing a plan, output it in this format (or save to `docs/plans/YYYY-MM-DD-<feature-name>.md`):

```markdown
# [Feature Name] Implementation Plan

> **Execution Directive**: Execute this plan via `/executing-plans` in inline mode. Complete each task, run verification, and commit atomically before moving to the next.

**Goal**: [One clear sentence describing what is being built]  
**Target Branch**: `feature/[feature-name]`  
**Affected Tech Stack**: [Flutter / Node TypeScript / Knex / etc.]

---

## Global & Architectural Constraints
- **UI & Styling (`AGENTS.md`)**: Strict NO drop shadows (`boxShadow`, `elevation`). Clean, borderless surfaces using `PulseColors`.
- **Responsive Overflow**: All rows/chips must use `Expanded`, `Flexible`, or `FittedBox` down to 280x520 viewports.
- **Backend (`AGENTS.md`)**: Mandatory Jest in `__tests__/`. Explicit error logging in catch blocks. Foreign key table indexing.

---

## Implementation Tasks

### Task 1: [Task Title]
- **Target Files**:
  - `mobile/lib/...` or `backend/src/...`
  - `mobile/test/...` or `backend/src/.../__tests__/...`
- **Action**:
  - [Step 1: Write test / define interfaces]
  - [Step 2: Implement code to fulfill requirements]
- **Verification Command**:
  - `flutter test test/path/to/test.dart` OR
  - `npx jest src/path/to/__tests__/test.test.ts`
- **Commit**: `feat(scope): descriptive commit message`

### Task 2: [Next Task Title]
- **Target Files**:
  - `path/to/file`
- **Action**:
  - [Implementation details]
- **Verification Command**:
  - [Verification command]
- **Commit**: `feat(scope): next commit message`

---

## 🏁 Checkpoint & Final Verification
- [ ] Run full project validation: `flutter analyze` / `npx tsc --noEmit`
- [ ] Verify 280x520 responsive layout test passes (if UI modified)
- [ ] Developer review of diffs and commit log
- [ ] Merge into target branch
```

---

## 🔄 Handoff to `executing-plans`

Once this plan is generated and approved by the developer, immediately proceed to execution using:
> **`/executing-plans`**
