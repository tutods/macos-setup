# Context Sets for Repomix

Repomix can be instructed to only pack specific subsets of the repository using "Context Sets". This allows you to focus the AI's attention on the most relevant parts of the codebase for a given task.

## Available Sets

### infra
- Focuses on infrastructure files: Nix modules, CI configs, Dockerfiles, Nix Homebrew definitions.
- Includes: `modules/`, `.github/workflows/`, `Dockerfile*`, `docker-compose.yml*`, any files related to system setup.

### app
- Focuses on the core application logic: source code, key components, and business logic.
- Includes: `src/`, `lib/`, `apps/`, any implementation files, but excludes `Dockerfile`, `README.md`.

### infra-apps
- Combines infrastructure with the main application components to help the AI understand how they interact.