# Golden Prompts Library

This directory contains high-quality, reusable prompt templates that guide the AI through common development workflows. Each prompt is version-controlled and can be invoked via the `@ai` alias or loaded directly into the `opencode` and `claude-code` environments.

## Prompt Sets

### 🛠️ code-review
**When to use:** Reviewing PRs, examining new code, checking for security issues.
**Description:** Provides the AI with strict code review standards, including a checklist for security, performance, and style compliance.

### 🔍 bug-hunt
**When to use:** Hunting for edge cases, replicating bugs, or analyzing crash logs.
**Description:** Trains the AI to think like a debugger: hypothesize failure modes, suggest root causes, and recommend fixes.

### 🧪 test-gen
**When to use:** Writing or improving test suites.
**Description:** Provides comprehensive test generation guidance with mock data, edge cases, and coverage goals.

### 📚 explain-docs
**When to use:** Understanding unfamiliar documentation or API references.
**Description:** Generates beginner-friendly explanations with analogies and practical usage examples.

## How to Use
- Select a file in this directory with the `@` prefix (e.g., `@code-review`) when starting a new conversation.
- The AI will automatically load the content as context for future turns.

## Prompts Library