# AI Tooling Overhaul — Design Spec

**Date:** 2026-05-15
**Scope:** `home/common/cli/ai/`, `home/roles/personal/ai/`, `home/roles/work/ai/`
**Applies to:** both machines (macbook + work), with personal-only additions

---

## Goals

1. Split skills into common (both machines) and personal-only manifests
2. Add new MCP servers: Playwright (common), Docker + Postgres + shadcn (personal)
3. Extend `options.nix` with `extraMcpServers` and `extraSkillsManifest`
4. Harden privacy for both Claude Code and opencode
5. Bring `~/.claude/CLAUDE.md` under Nix management
6. Add skills sync hash guard to skip unchanged manifests on rebuild

---

## 1. Skills

### 1.1 Manifest split

Replace single `home/common/cli/ai/skills/manifest.txt` with two files:

**`home/common/cli/ai/skills/manifest.txt`** — installed on both machines, both agents:

```
anthropics/knowledge-work-plugins        # code-review
anthropics/skills                        # frontend-design
JuliusBrussee/caveman                   # caveman-commit, caveman-compress, caveman-help, caveman-review, compress
mattpocock/skills -s grill-with-docs
obra/superpowers                         # brainstorming, requesting-code-review, systematic-debugging, test-driven-development, using-superpowers, writing-plans
pbakaus/impeccable
secondsky/claude-skills                  # tailwind-v4-shadcn
shadcn/ui                                # shadcn
vercel-labs/agent-skills                 # web-design-guidelines
vercel-labs/skills                       # find-skills
kadajett/agent-nestjs-skills -s nestjs-best-practices
wshobson/agents                          # api-design-principles, nodejs-backend-patterns, responsive-design
OpenAEC-Foundation/Docker-Claude-Skill-Package   # 22 docker skills
SpillwaveSolutions/mastering-typescript-skill
```

**`home/roles/personal/ai/skills/manifest.txt`** — personal machine only, both agents:

```
better-auth/skills                       # better-auth-best-practices
Leonxlnx/taste-skill                    # 12 design/imagegen skills
mindrally/skills                         # sanity
oakoss/agent-skills                      # tanstack-start
prisma/skills                            # prisma-postgres
resciencelab/opc-skills                  # seo-geo
squirrelscan/skills                      # audit-website
tanstack/router                          # start-core
vercel/turborepo
```

**Removed:** `safishamsi/graphify` from common manifest.

### 1.2 Installation target

`ai-skills-sync` already installs with `-a claude-code -a opencode` — no change needed. Both manifests (common + personal extra) feed the same function.

### 1.3 `skills/default.nix` changes

- Accept `extraSkillsManifest` lines (from `options.nix`) and append them to the manifest path used at sync time
- The combined manifest (common + extra) is what gets hashed for the guard (see §6)

---

## 2. MCP Servers

### 2.1 Common (both machines, both agents)

| Server | Command | Notes |
|---|---|---|
| `filesystem` | `npx -y @modelcontextprotocol/server-filesystem ~/.dotfiles ~/Developer` | unchanged |
| `github` | `sh -c 'GITHUB_PERSONAL_ACCESS_TOKEN="${GITHUB_TOKEN:-}" npx -y @modelcontextprotocol/server-github'` | unchanged |
| `playwright` | `npx -y @playwright/mcp --isolated --headless` | new — `--isolated` keeps browser profile in memory only (no cookies/sessions persisted to disk) |

### 2.2 Personal only (macbook, both agents)

Deployed via `home.ai.extraMcpServers` in `home/roles/personal/ai/default.nix`.

The `extraMcpServers` activation writes to **both**:
- `~/.claude/claude_desktop_config.json` (Claude Code)
- `~/.config/opencode/opencode.json` (opencode)

| Server | Command | Notes |
|---|---|---|
| `docker` | `docker/docker-mcp-server` (official Docker MCP) | container/image/volume/compose management |
| `postgres` | `doppler run -- npx @modelcontextprotocol/server-postgres` | reads `DATABASE_URL` from Doppler; must point to local dev DB only, never prod |
| `shadcn` | `npx shadcn@latest mcp` | official shadcn/ui registry — browse/search/install components; no auth needed |

**Security note (Docker MCP):** The Docker MCP can read container environment variables. Do not store secrets as plain env vars in containers — use Docker secrets or bind-mounted files instead.

---

## 3. `options.nix` — new options

Add two options alongside the existing `extraInstructions`:

```nix
options.home.ai = {
  extraInstructions = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Extra instructions appended to workflow.md (Claude Code) and AGENTS.md (opencode)";
  };

  extraMcpServers = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = "Role-specific MCP servers merged into both claude_desktop_config.json and opencode.json";
  };

  extraSkillsManifest = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Extra skill install lines appended to the personal manifest, installed to both agents";
  };
};
```

**No `extraPlugins` option.** Claude Code marketplace plugins are the same on both machines — managed directly in `claude/default.nix`. Role differences are skills-based, not plugin-based.

---

## 4. Privacy — Claude Code

Add to the `settings` attrset in `claude/default.nix`:

```nix
telemetry.enabled = false;  # already present

permissions.deny = [
  "Read(./.env)"
  "Read(./.env.*)"
  "Read(./secrets/**)"
  "Read(~/.config/fish/secrets.fish)"  # protects token storage
];

env.CLAUDE_CODE_SKIP_PROMPT_HISTORY = "1";  # no prompts written to history.jsonl
```

**Why `secrets.fish` explicitly:** This file holds `GITHUB_TOKEN`, `CONTEXT7_API_KEY`, etc. The deny rule prevents Claude Code from reading it even if accidentally asked.

**Note:** Transcripts in `~/.claude/projects/` are plaintext (OS file permissions only). `SKIP_PROMPT_HISTORY` reduces exposure. No further encryption available at the tool level.

---

## 5. Privacy — opencode

Add to `opencodeBaseConfig` in `mcp/default.nix`:

```nix
snapshot = false;           # disable conversation snapshot storage (default: true)
logLevel = "WARN";          # reduce local log verbosity (default: INFO)
disabled_providers = [      # prevent accidental connections to unused providers
  "openai" "azure" "vertex" "bedrock"
];
permission.bash = {
  "git *" = "allow";        # git ops auto-approved
  "*" = "ask";              # all other shell commands require confirmation
};
```

`share = "disabled"` and `experimental.openTelemetry = false` and `autoupdate = "manual"` already set — unchanged.

---

## 6. Skills sync hash guard

Update `init.nix` to skip `ai-skills-sync` when neither manifest has changed:

The combined manifest (common + extra lines from `extraSkillsManifest`) is written to a temp file by the activation script in `skills/default.nix` at build time. `init.nix` hashes that file path (a Nix store path, stable until manifest content changes):

```bash
manifest_hash=$(sha256sum "${combinedManifestStorePath}" | cut -d' ' -f1)
stamp="$HOME/.config/ai/.skills-sync-hash"

if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$manifest_hash" ]; then
  echo "↣ AI skills sync (manifest changed)"
  fish -c "ai-skills-sync" && echo "$manifest_hash" > "$stamp" \
    || echo "  ⚠ ai-skills-sync failed"
else
  echo "↣ AI skills up to date"
fi
```

`combinedManifestStorePath` is a Nix value passed from `skills/default.nix` to `init.nix` via a shared let binding in `default.nix`. Because Nix store paths are content-addressed, the hash changes exactly when the manifest content changes.

The stamp file lives at `~/.config/ai/.skills-sync-hash` — not committed, machine-local.

---

## 7. CLAUDE.md — Nix-managed

**Problem:** `~/.claude/CLAUDE.md` is currently hand-edited, outside Nix. It contains a stale `graphify` entry.

**Solution:** Deploy via `home.file.".claude/CLAUDE.md"` in `claude/default.nix`.

Content: shared base (`@RTK.md` reference, graphify removed). Role-specific additions are appended inline in each role's nix file — no new option needed since CLAUDE.md additions are rare and Claude Code-specific.

**opencode equivalent:** `~/.config/opencode/AGENTS.md` is already Nix-managed via `instructions/default.nix`. No additional action needed.

---

## File changes summary

| File | Change |
|---|---|
| `home/common/cli/ai/skills/manifest.txt` | Remove graphify, add Docker + TS mastery skills |
| `home/common/cli/ai/skills/default.nix` | Accept `extraSkillsManifest`; write combined manifest at sync time |
| `home/common/cli/ai/init.nix` | Add hash guard around skills sync |
| `home/common/cli/ai/mcp/default.nix` | Add playwright to common servers; add `extraMcpServers` dual-write activation; add opencode privacy settings |
| `home/common/cli/ai/claude/default.nix` | Add `permissions.deny` + `CLAUDE_CODE_SKIP_PROMPT_HISTORY`; deploy `CLAUDE.md` |
| `home/common/cli/ai/options.nix` | Add `extraMcpServers` + `extraSkillsManifest` |
| `home/roles/personal/ai/default.nix` | Set `extraMcpServers` (docker, postgres, shadcn); set `extraSkillsManifest` |
| `home/roles/personal/ai/skills/manifest.txt` | New file — 9 personal-only skill sources |

---

## Out of scope

- Work role MCP additions (no personal-only MCPs needed there)
- `extraPlugins` option (not needed — plugin differences are skills-based)
- Conversation history encryption (not configurable at the tool level)
- Pinning AI tool versions (separate concern, tracked separately)
