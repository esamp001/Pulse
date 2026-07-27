---
name: ask-mode
description: Interactive advisory mode that asks clarifying questions, presents implementation options with pros/cons, provides code examples, and outlines edge cases before writing code. Triggered via /ask-mode.
---

# Ask Mode Skill Guidelines (/ask-mode)

When `/ask-mode` is invoked or when advisory mode is requested, follow this interactive workflow **INSTEAD of immediately making source code edits**:

---

## 📋 Core Directives

1. **DO NOT MODIFY CODE IMMEDIATELY**: Pause all automated file modifications until requirements and design choices are clarified with the user.
2. **ASK CLARIFYING QUESTIONS**: Solicit design intent and clarify ambiguity using the `ask_question` tool or structured interactive prompts.
3. **PRESENT CHOICE OPTIONS WITH PROS & CONS**:
   - **Option 1 (Recommended)**: Best practice approach with rationale.
   - **Option 2 (Alternative)**: Viable secondary approach.
   - **What NOT to Choose**: Highlight anti-patterns, performance pitfalls, or poor choices to avoid.
4. **IDENTIFY EDGE CASES**: List critical edge cases, failure modes, null/error states, and security/performance considerations.
5. **PROVIDE CODE EXAMPLES**: Show clean, concise reference code snippets illustrating the recommended pattern so the user can review before execution.

---

## 🛠️ Step-by-Step Response Format

When answering under `/ask-mode`, structure your response as follows:

```markdown
### 🎯 Problem & Requirements Analysis
[Brief 2-3 sentence overview of what needs to be solved]

### 💡 Implementation Options

#### Option A: [Recommended Approach Title] (Recommended)
- **Description**: Summary of how this approach works.
- **Pros**: Clear benefits.
- **Cons**: Trade-offs or complexity.
- **Example Code Snippet**:
  ```dart/typescript
  // Clean reference code snippet
  ```

#### Option B: [Alternative Approach Title]
- **Description**: Alternative strategy.
- **Pros & Cons**: Key trade-offs.

#### 🛑 What NOT to Choose (Anti-patterns)
- [Detail poor practices or pitfalls to avoid and why]

### ⚠️ Edge Cases & Pitfalls to Consider
1. **Edge Case 1**: Description & mitigation.
2. **Edge Case 2**: Description & mitigation.
3. **Edge Case 3**: Description & mitigation.

### ❓ Interactive Questions
[Use ask_question tool or clear choices for user selection]
```

---

## 🚀 Execution Strategy
After the user reviews your suggestions and selects an option, transition from `/ask-mode` into implementation mode to make the agreed-upon changes cleanly and verify them.
