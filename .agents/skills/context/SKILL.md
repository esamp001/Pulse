---
name: context
description: Reads the root README.md for overview, scans and reads all markdown (.md) files in the docs/ directory and subfolders to gather full architecture and coding standards context before coding. Use via /context or trigger when coding context is needed.
---

# Context & Coding Standards Skill (`context`)

This skill ensures that the agent scans all project specifications and coding standards before generating or modifying any code in the codebase.

---

## 📋 Execution Protocol

Whenever this skill is triggered or invoked (e.g. via `/context`):

### Step 1: Read Root Overview
- Open and inspect the root [`README.md`](file:///c:/Users/ellejun.sampaga/Documents/Pulse/README.md).
- Understand the overall project vision, MVP goals, user roles (Player vs. Scorer), tech stack, and high-level architecture.

### Step 2: Scan & Read All `.md` Files in `docs/`
- Recursively find and read every `.md` file inside `docs/` and its subdirectories (`docs/backend/`, `docs/frontend/`, `docs/modules/`, `docs/components/`, `docs/global/`).
- Specifically ensure reading:
  - [`docs/Readme.md`](file:///c:/Users/ellejun.sampaga/Documents/Pulse/docs/Readme.md) - Spec-driven documentation map.
  - [`docs/coding standard.md`](file:///c:/Users/ellejun.sampaga/Documents/Pulse/docs/coding%20standard.md) - Coding standards, naming conventions, and layer boundaries.

### Step 3: Present Context Summary
- Output a concise summary to the user highlighting:
  1. Key architectural patterns applicable to the task.
  2. Specific coding standards and naming conventions to follow.
  3. Identified database schemas, services, or component contracts relevant to the task.

### Step 4: Begin Implementation
- Proceed with writing clean, compliant code that strictly adheres to the scanned context and standards.
