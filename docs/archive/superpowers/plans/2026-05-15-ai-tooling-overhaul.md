# AI Tooling Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split skills manifests by role, add Playwright/Docker/Postgres/shadcn MCPs, harden privacy for Claude Code and opencode, bring CLAUDE.md under Nix management, and add skills sync hash guard.

**Architecture:** All changes are Home Manager Nix module edits — no new packages, no new flake inputs. Tasks are mostly independent and can be verified with `nix flake check --no-build` after each one. Full integration test requires `./nix.sh macbook --build-only` and then a `darwin-rebuild switch`.

**Tech Stack:** Nix, Home Manager, jq, fish shell, `npx skills`, Claude Code settings.json, opencode.json

---

## File Map

| File | Action | What changes |
|---|---|---|
| `home/common/cli/ai/options.nix` | Modify | Add `extraMcpServers` + `extraSkillsManifest` options |
| `home/common/cli/ai/skills/manifest.txt` | Modify | Remove personal skills + graphify; add Docker + TS mastery |
| `home/common/cli/ai/skills/default.nix` | Modify | Combined manifest via `pkgs.writeText`; hash-guard activation |
| `home/common/cli/ai/init.nix` | Modify | Remove skills sync call (now owned by skills/default.nix) |
| `home/common/cli/ai/mcp/default.nix` | Modify | Add playwright; `extraMcpServers` dual-write; opencode privacy |
| `home/common/cli/ai/claude/default.nix` | Modify | Privacy settings; deploy `~/.claude/CLAUDE.md` |
| `home/roles/personal/ai/default.nix` | Modify | Set `extraMcpServers` + `extraSkillsManifest` |
| `home/roles/personal/ai/skills/manifest.txt` | Create | 9 personal-only skill sources |

---

## Task 1: Extend `options.nix` with two new options

**Files:**
- Modify: `home/common/cli/ai/options.nix`

- [ ] **Step 1: Replace `options.nix` with the extended version**

```nix
{lib, ...}: {
  options.home.ai = {
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    extraMcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Role-specific MCP servers merged into both claude_desktop_config.json and opencode.json";
    };

    extraSkillsManifest = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra skill install lines appended to the common manifest, installed to both agents";
    };
  };
}
```

- [ ] **Step 2: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error|done'
```

Expected: no errors (only the usual dirty-tree warning).

- [ ] **Step 3: Commit**

```bash
git add home/common/cli/ai/options.nix
git commit -m "feat(ai): add extraMcpServers and extraSkillsManifest options"
```

---

## Task 2: Update common skills manifest

**Files:**
- Modify: `home/common/cli/ai/skills/manifest.txt`

- [ ] **Step 1: Replace the manifest content**

```
# AI Skills Manifest — common (both machines, both agents)
# Installed via: npx skills add <source> -g -a claude-code -a opencode -y
#
# Personal-only skills live in home/roles/personal/ai/skills/manifest.txt
#
# Harness built-ins (NOT installable — shipped with Claude Code harness):
#   update-config, loop, schedule, simplify, fewer-permission-prompts,
#   keybindings-help, statusline-setup, init, review, security-review, claude-api

anthropics/knowledge-work-plugins        # code-review
anthropics/skills                        # frontend-design
JuliusBrussee/caveman                   # caveman-commit, caveman-compress, caveman-help, caveman-review, compress
mattpocock/skills -s grill-with-docs    # grill-with-docs
obra/superpowers                         # brainstorming, requesting-code-review, systematic-debugging, test-driven-development, using-superpowers, writing-plans
pbakaus/impeccable                       # impeccable
secondsky/claude-skills                  # tailwind-v4-shadcn
shadcn/ui                                # shadcn
vercel-labs/agent-skills                 # web-design-guidelines
vercel-labs/skills                       # find-skills
kadajett/agent-nestjs-skills -s nestjs-best-practices
wshobson/agents                          # api-design-principles, nodejs-backend-patterns, responsive-design
OpenAEC-Foundation/Docker-Claude-Skill-Package
SpillwaveSolutions/mastering-typescript-skill
```

- [ ] **Step 2: Verify no typos — check file saved correctly**

```bash
wc -l home/common/cli/ai/skills/manifest.txt
grep -c '^[^#]' home/common/cli/ai/skills/manifest.txt
```

Expected: 14 non-comment lines.

- [ ] **Step 3: Commit**

```bash
git add home/common/cli/ai/skills/manifest.txt
git commit -m "feat(ai/skills): update common manifest — add docker/ts-mastery, move personal skills out"
```

---

## Task 3: Create personal skills manifest

**Files:**
- Create: `home/roles/personal/ai/skills/manifest.txt`

- [ ] **Step 1: Create the file**

```
# AI Skills Manifest — personal machine only (both agents)
# Installed via extraSkillsManifest → ai-skills-sync on darwin-rebuild

better-auth/skills                       # better-auth-best-practices
Leonxlnx/taste-skill                    # brandkit, design-taste-frontend, full-output-enforcement, gpt-taste, high-end-visual-design, image-to-code, imagegen-frontend-mobile, imagegen-frontend-web, industrial-brutalist-ui, minimalist-ui, redesign-existing-projects, stitch-design-taste
mindrally/skills                         # sanity
oakoss/agent-skills                      # tanstack-start
prisma/skills                            # prisma-postgres
resciencelab/opc-skills                  # seo-geo
squirrelscan/skills                      # audit-website
tanstack/router                          # start-core
vercel/turborepo                         # turborepo
```

- [ ] **Step 2: Commit**

```bash
git add home/roles/personal/ai/skills/manifest.txt
git commit -m "feat(ai/skills): add personal-only skills manifest"
```

---

## Task 4: Rewrite `skills/default.nix` — combined manifest + hash guard

**Files:**
- Modify: `home/common/cli/ai/skills/default.nix`

- [ ] **Step 1: Replace the file**

```nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  commonManifest = builtins.readFile ./manifest.txt;
  extra = config.home.ai.extraSkillsManifest;
  combinedContent = commonManifest + (
    if extra != ""
    then "\n" + extra
    else ""
  );
  combinedManifest = pkgs.writeText "ai-skills-manifest" combinedContent;
  manifestHash = builtins.hashString "sha256" combinedContent;
in {
  programs.fish.functions.ai-skills-sync = {
    description = "Install AI skills from manifest into Claude Code and opencode";
    body = ''
      set -l manifest "${combinedManifest}"
      set -l agents_flag "-a" "claude-code" "-a" "opencode"
      set -l installed 0
      set -l failed 0

      if not test -f "$manifest"
        echo "Skills manifest not found at $manifest"
        return 1
      end

      while read -l line
        set -l line (string trim "$line")
        if test -z "$line"; or string match -q '#*' "$line"; continue; end

        set -l clean_line (string replace -r '#.*' "" -- "$line")
        set -l clean_line (string trim "$clean_line")
        if test -z "$clean_line"; continue; end

        echo "▸ npx skills add $clean_line -g $agents_flag -y"
        if npx skills add $clean_line -g $agents_flag -y 2>&1
          set installed (math $installed + 1)
        else
          echo "  ⚠ Failed: $clean_line"
          set failed (math $failed + 1)
        end
      end < "$manifest"

      echo ""
      echo "Skills install complete: $installed succeeded, $failed failed"
    '';
  };

  home.activation.aiSkillsSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    stamp="$HOME/.config/ai/.skills-sync-hash"
    manifest_hash="${manifestHash}"

    mkdir -p "$HOME/.config/ai"

    if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$manifest_hash" ]; then
      echo "↣ AI skills sync (manifest changed)"
      if command -v fish > /dev/null 2>&1; then
        fish -c "ai-skills-sync" \
          && echo "$manifest_hash" > "$stamp" \
          || echo "  ⚠ ai-skills-sync failed"
      fi
    else
      echo "↣ AI skills up to date"
    fi
  '';
}
```

- [ ] **Step 2: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error'
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home/common/cli/ai/skills/default.nix
git commit -m "feat(ai/skills): combined manifest with extraSkillsManifest + hash guard activation"
```

---

## Task 5: Remove skills sync from `init.nix`

Skills sync is now owned by `skills/default.nix`. Remove the duplicate call from `init.nix`.

**Files:**
- Modify: `home/common/cli/ai/init.nix`

- [ ] **Step 1: Remove the AI skills block from `init.nix`**

Delete lines 35–40 (the `── AI skills` section):

```nix
# Before (delete this block entirely):
    # ── AI skills ─────────────────────────────────────────────────────────
    # fish function reads manifest.txt and runs `npx skills add` for each entry
    if command -v fish > /dev/null 2>&1; then
      echo "↣ AI skills sync"
      fish -c "ai-skills-sync" || echo "  ⚠ ai-skills-sync failed (check manifest.txt)"
    fi
```

The file after edit should end with the pipx block and the closing `''` + `};` + `}`.

- [ ] **Step 2: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error'
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home/common/cli/ai/init.nix
git commit -m "refactor(ai/init): remove skills sync — now owned by skills/default.nix"
```

---

## Task 6: Update `mcp/default.nix` — playwright, extraMcpServers, opencode privacy

**Files:**
- Modify: `home/common/cli/ai/mcp/default.nix`

- [ ] **Step 1: Add playwright to common servers and opencode privacy settings**

In the `let` block, add playwright server definition after `filesystemServer`:

```nix
  playwrightServer = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };
```

Add it to both `claudeMcpServers` and `opencodeMcpServers`:

```nix
  claudeMcpServers = {
    filesystem = filesystemServer;
    github = githubServer;
    playwright = playwrightServer;
  };

  opencodeMcpServers = {
    filesystem = filesystemServer // { type = "local"; enabled = true; };
    github = githubServer // { type = "local"; enabled = true; };
    playwright = playwrightServer // { type = "local"; enabled = true; };
  };
```

Update `opencodeBaseConfig` to add privacy settings:

```nix
  opencodeBaseConfig = {
    "\$schema" = "https://opencode.ai/config.json";
    plugin = ["@warp-dot-dev/opencode-warp"];
    experimental.openTelemetry = false;
    share = "disabled";
    autoupdate = "manual";
    snapshot = false;
    logLevel = "WARN";
    disabled_providers = ["openai" "azure" "vertex" "bedrock"];
    permission.bash = {
      "git *" = "allow";
      "*" = "ask";
    };
  };
```

- [ ] **Step 2: Add `extraMcpServers` dual-write activations**

The module signature must accept `config`:

```nix
{
  config,
  pkgs,
  lib,
  ...
}:
```

Add two new activations after the existing `opencodeMcp` activation, inside the `in { ... }` block:

```nix
  # Writes role-specific extra MCP servers to both tools.
  # Runs after the common MCP activations.
  home.activation.claudeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "claudeMcp"] ''
    extra_servers='${builtins.toJSON config.home.ai.extraMcpServers}'
    if [ "$extra_servers" = "{}" ]; then
      :
    else
      target="$HOME/.claude/claude_desktop_config.json"
      ${pkgs.jq}/bin/jq --argjson extra "$extra_servers" \
        '. + {mcpServers: (.mcpServers + $extra)}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';

  home.activation.opencodeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "opencodeMcp"] ''
    raw_servers='${builtins.toJSON config.home.ai.extraMcpServers}'
    if [ "$raw_servers" = "{}" ]; then
      :
    else
      # Add type=local and enabled=true to each extra server for opencode
      extra_servers=$(echo "$raw_servers" | ${pkgs.jq}/bin/jq \
        'to_entries | map(.value += {"type": "local", "enabled": true}) | from_entries')
      target="$HOME/.config/opencode/opencode.json"
      ${pkgs.jq}/bin/jq --argjson extra "$extra_servers" \
        '. + {mcp: (.mcp + $extra)}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
```

- [ ] **Step 3: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error'
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add home/common/cli/ai/mcp/default.nix
git commit -m "feat(ai/mcp): add playwright MCP, extraMcpServers dual-write, opencode privacy hardening"
```

---

## Task 7: Update `claude/default.nix` — privacy settings + CLAUDE.md

**Files:**
- Modify: `home/common/cli/ai/claude/default.nix`

- [ ] **Step 1: Add privacy settings to the `settings` attrset**

In the `settings` let-binding, add after `telemetry.enabled = false;`:

```nix
    permissions.deny = [
      "Read(./.env)"
      "Read(./.env.*)"
      "Read(./secrets/**)"
      "Read(~/.config/fish/secrets.fish)"
    ];

    env.CLAUDE_CODE_SKIP_PROMPT_HISTORY = "1";
```

- [ ] **Step 2: Add CLAUDE.md deployment**

In the `in { ... }` block, after the `home.activation.claudeSettings` block, add:

```nix
  home.file.".claude/CLAUDE.md".text = ''
    @RTK.md
  '';
```

- [ ] **Step 3: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error'
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add home/common/cli/ai/claude/default.nix
git commit -m "feat(ai/claude): add permissions.deny, SKIP_PROMPT_HISTORY, manage CLAUDE.md via Nix"
```

---

## Task 8: Update `home/roles/personal/ai/default.nix` — wire extraMcpServers + extraSkillsManifest

**Files:**
- Modify: `home/roles/personal/ai/default.nix`

- [ ] **Step 1: Replace the file**

```nix
{...}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  home.ai.extraSkillsManifest = builtins.readFile ./skills/manifest.txt;

  home.ai.extraMcpServers = {
    # Docker MCP — official image, mounts Docker socket
    # WARNING: can read container env vars; do not use plain env vars for secrets in containers
    docker = {
      command = "docker";
      args = [
        "run"
        "--rm"
        "-i"
        "--mount"
        "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock"
        "docker/docker-mcp-server"
      ];
    };

    # Postgres MCP — DATABASE_URL injected by Doppler at spawn time
    # Must point to local dev DB only — never production
    postgres = {
      command = "sh";
      args = ["-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
    };

    # shadcn/ui MCP — official registry, no auth needed
    shadcn = {
      command = "npx";
      args = ["shadcn@latest" "mcp"];
    };
  };
}
```

- [ ] **Step 2: Verify evaluation**

```bash
nix flake check --no-build 2>&1 | grep -E 'error'
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add home/roles/personal/ai/default.nix
git commit -m "feat(ai/personal): wire extraMcpServers (docker/postgres/shadcn) and extraSkillsManifest"
```

---

## Task 9: Integration test

- [ ] **Step 1: Full build**

```bash
./nix.sh macbook --build-only
```

Expected: build completes with no errors.

- [ ] **Step 2: Apply**

```bash
./nix.sh macbook
```

- [ ] **Step 3: Verify Claude Code settings**

```bash
jq '.permissions.deny, .env.CLAUDE_CODE_SKIP_PROMPT_HISTORY, .telemetry' ~/.claude/settings.json
```

Expected:
```json
["Read(./.env)","Read(./.env.*)","Read(./secrets/**)","Read(~/.config/fish/secrets.fish)"]
"1"
{"enabled":false}
```

- [ ] **Step 4: Verify opencode settings**

```bash
jq '{snapshot, logLevel, disabled_providers, permission, share, autoupdate}' ~/.config/opencode/opencode.json
```

Expected:
```json
{
  "snapshot": false,
  "logLevel": "WARN",
  "disabled_providers": ["openai","azure","vertex","bedrock"],
  "permission": {"bash": {"git *": "allow", "*": "ask"}},
  "share": "disabled",
  "autoupdate": "manual"
}
```

- [ ] **Step 5: Verify Claude Code MCPs**

```bash
jq '.mcpServers | keys' ~/.claude/claude_desktop_config.json
```

Expected: `["filesystem","github","playwright"]`

- [ ] **Step 6: Verify personal MCPs in opencode**

```bash
jq '.mcp | keys' ~/.config/opencode/opencode.json
```

Expected: `["docker","filesystem","github","playwright","postgres","shadcn"]`

- [ ] **Step 7: Verify CLAUDE.md**

```bash
cat ~/.claude/CLAUDE.md
```

Expected:
```
@RTK.md
```

- [ ] **Step 8: Verify skills hash stamp created**

```bash
cat ~/.config/ai/.skills-sync-hash
```

Expected: a 64-character sha256 hex string. Presence of file confirms skills sync ran and hash guard is active.

- [ ] **Step 9: Verify hash guard skips on second rebuild**

```bash
./nix.sh macbook 2>&1 | grep 'AI skills'
```

Expected: `↣ AI skills up to date` (not `manifest changed`).
