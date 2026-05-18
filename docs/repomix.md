# Repomix

Repomix packs this repo (or a subset) into a single AI-readable file for sharing context across tools or sessions.

## Usage

Config at `repomix.config.json` in the repo root. Default output: `/tmp/dotfiles-context.md`.

```bash
# Pack entire repo
repomix

# Pack a specific context set (see below)
repomix --context infra
repomix --context app
```

## Context sets

Repomix supports focused subsets of the repo for specific tasks. Define them with the `--context` flag or in `repomix.config.json`.

### `infra`

Infrastructure files only: Nix modules, CI configs, Dockerfiles, nix-homebrew definitions.

Includes: `modules/`, `.github/workflows/`, `Dockerfile*`, `docker-compose.yml*`, any files related to system setup.

**Use when:** Diagnosing a Nix build issue, updating modules, debugging CI, or asking about system configuration.

### `app`

Core application logic: source code, key components, business logic.

Includes: `src/`, `lib/`, `apps/`, implementation files. Excludes `Dockerfile`, `README.md`.

**Use when:** Working on app features, refactoring, debugging application behavior.

### `infra-apps`

Combined infra + application. Helps the AI understand how infrastructure and application interact.

**Use when:** Questions that span both layers — e.g. "why does my deploy fail when I change X".

## Workflow tip

Before switching tools mid-session or sharing context with a non-Claude AI:

```bash
repomix              # pack current state
# then pass /tmp/dotfiles-context.md to the other tool
```
