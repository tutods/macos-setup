# Review: full setup, 2026-08-30

Full-repo deep review (6 dimensions, every CRITICAL/MAJOR adversarially verified by a
second agent) plus an LLM council run (advisors on opus/sonnet/haiku, opus peer review
and chairman). Mechanical checks: `nix flake check` **passed**, `./scripts/verify-plugins.sh`
**passed** (18 plugins, every checkable entry resolves).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 4 |
| MAJOR | 10 |
| MINOR | 40 |

**Fix session (2026-08-30):** every item fixed and verified except one deferral
(`mp-conventions.md`, needs the owner's decision on where employer data lives)
and one no-change (`delegate-nudge.sh`, the flagged `prompt_id` field is
documented). Also landed in the same session, by request: marketplaces pinned
to reviewed commit SHAs (settings.nix parses `owner/repo@sha`,
verify-plugins.sh validates against the pin), the `rtk` CLI added via
Homebrew with a guarded PreToolUse rewrite hook (`rtk-rewrite.sh`), and a new
`harness-engineer` skill distilling Anthropic's harness-design article. Plus
one extra bug found while fixing: deploy-doctor's unquoted dotted username.

## Checklist

### CRITICAL

- [x] **[CRITICAL]** `home/common/ai/plugins.nix:9`, all 10 third-party marketplaces are declared as bare `owner/repo` and emitted by `settings.nix:126` with no ref/commit — skills from strangers' repos execute at HEAD on the work laptop next to client repos and Jira credentials, while nixpkgs itself is hash-pinned; `verify-plugins.sh` checks names resolve, not content. Fix: pin each marketplace to a reviewed commit or delete the ones without a skill you actually invoke, effort: M
- [x] **[CRITICAL]** `home/common/editors/zed/default.nix:40`, `zedSeedSettings` runs `run install` unconditionally on every activation, clobbering whatever Zed saved since the last deploy — CLAUDE.md says app-written configs are seeded one-time (git history shows the guard was lost in e524255). Fix: wrap in `if [ ! -f ... ]` guard + `mkdir -p`, effort: S
- [x] **[CRITICAL]** `home/common/editors/orca/default.nix:10`, same bug: the comment promises a one-time seed, but `run install` runs every deploy, destroying keybinding changes Orca writes back. Fix: `[ ! -f ... ]` guard, effort: S
- [x] **[CRITICAL]** `home/common/shell/fish/functions.nix:113`, `node_clean` pipes paths through `printf | xargs rm -rf`; xargs splits on whitespace, so a path with a space runs `rm -rf` on wrong cwd-relative tokens. Fix: `rm -rf $targets` (fish lists don't word-split) or `fd --print0 | xargs -0`, effort: S

### MAJOR

- [x] **[MAJOR]** `home/common/ai/settings.nix:119`, the PostToolUse biome hook (a) executes the project-controlled `./node_modules/.bin/biome` with no permission prompt — a cloned repo shipping a committed `biome.json` + malicious binary gets code execution on the first edit, bypassing the Bash permission system, and (b) runs `check --write` with no path argument, sweeping the whole project after a single edit, contradicting the repo's own scope-guard rule (`instructions/model-quality.md:11`); it's also the only hook with no timeout. Fix: drop the `node_modules` fallback (PATH-installed biome only), pass the edited file path from the hook's stdin JSON, add a timeout, effort: S
- [x] **[MAJOR]** `.github/renovate.json:50`, `matchDatasources: ["nix-flake"]` matches nothing (Renovate's nix manager uses the `git-refs` datasource), so all four nix packageRules are inert and the automerge behavior CLAUDE.md documents never happens; only lockFileMaintenance behaves as configured. Fix: `matchDatasources: ["git-refs"]` or `matchManagers: ["nix"]` in all four rules, effort: S
- [x] **[MAJOR]** `.github/renovate.json:67`, `matchPackageNames: ["NixOS/nixpkgs"]` (and lines 78-82) match neither depName (flake input name, e.g. `nixpkgs`) nor packageName (full URL) — the grouping/separation rules stay inert even after the datasource fix. Fix: `matchDepNames: ["nixpkgs"]` / `["home-manager","nix-darwin","nix-homebrew"]`, effort: S
- [x] **[MAJOR]** `nix.sh:321`, `setup_private_git` returns 1 on blank name/email right after printing "Skipping…", but the untested call at line 558 under `set -euo pipefail` kills the whole script — build and apply never run; `read -rp` also dies on non-interactive stdin. Fix: `|| true` at the call site or `return 0` on the skip path + `[[ -t 0 ]]` guard, effort: S
- [x] **[MAJOR]** `home/common/shell/fish/functions.nix:22`, `stashAndPull`: `git stash` on a clean tree stashes nothing, then `git stash pop` pops a pre-existing stash, dumping unrelated old changes into the tree. Fix: only pop if a stash was created, or replace the body with `git pull --rebase --autostash`, effort: S
- [x] **[MAJOR]** `docs/secrets.md:64`, claims missing secret files only warn and "the deploy still succeeds" — `checkSecrets` (`home/common/default.nix:36-47`) hard-fails activation with `exit 1` when `~/.config/git/private` is missing; contradicts architecture.md:150 which has it right. Fix: rewrite the Validation section, effort: S
- [x] **[MAJOR]** `docs/recovery.md:15`, bootstrap clone URL is `tutods/.dotfiles.git` but the repo is `tutods/macos-setup` — the recovery doc's first step 404s on a fresh machine. Fix: correct the URL, effort: S
- [x] **[MAJOR]** `docs/adding-host-or-user.md:83`, says to create `home/roles/<role>.nix` and pass "a new role name" — roles are directories and `lib/mkUser.nix` hardcodes the role map with a `?` guard, so following the doc yields a silent no-op. Fix: document the real steps (dir + roleModule map entry) and the silent-skip behavior, effort: S
- [x] **[MAJOR]** `docs/architecture.md:53`, package table is stale in placement-misleading ways: doppler attributed to `modules/packages/cli.nix` (it's macbook-host-only), development.nix said to contain terraform/JetBrains (contains claude-code + pipx). Fix: update both rows, effort: S
- [x] **[MAJOR]** `home/common/ai/skills/local/nix-setup/SKILL.md:22`, duplicates CLAUDE.md's mandatory-check list and has drifted: omits `deploy-doctor.sh` (mandatory per docs/nix-conventions.md), tree omits delegation-reminder.sh and maintenance.nix — an agent following the skill skips a mandatory pre-deploy check. Fix: sync now; longer term make the skill point into CLAUDE.md instead of copying it, effort: S

### MINOR

#### Nix correctness

- [x] **[MINOR]** `modules/packages/fonts.nix:5`, all fonts from `pkgsUnstable` with no justification (convention: stable unless too old; stable 25.11 has `nerd-fonts.*`). Fix: switch to `pkgs` or add the justifying comment, effort: S
- [x] **[MINOR]** `modules/packages/development.nix:4`, `pipx.overridePythonAttrs {doCheck = false;}` from unstable with no comment, unlike the documented worktrunk exception next to it. Fix: try stable `pkgs.pipx`, else document why, effort: S
- [x] **[MINOR]** `hosts/darwin/macbook/packages.nix:13`, `pkgsUnstable.opencode` carries no justification comment. Fix: comment or move to stable, effort: S
- [x] **[MINOR]** `lib/mkUser.nix:26`, `roleModule ? ${role}` silently skips unknown roles — a typo (`role = "wrok"`) deploys successfully with no role config. Fix: `roleModule.${role} or (throw "mkUser: unknown role '${role}'")`, effort: S
- [x] **[MINOR]** `lib/ai.nix:130`, `jq … > tmp && mv` in mergeJsonKey/mergeJsonObject: a jq failure is silently skipped under HM's `set -e` (command before `&&` is errexit-exempt), leaving stale config + orphan `.tmp`. Fix: add an explicit `|| { echo …; exit 1; }` branch, effort: M
- [x] **[MINOR]** `home/common/default.nix:19`, `createDeveloperDir` hardcodes `~/Developer` instead of `config.home.devDir`, the option that exists precisely for this. Fix: use the option, effort: S
- [x] **[MINOR]** `home/common/ai/instructions/default.nix:19`, `config.home.ai.extraInstructions or ""` — dead fallback (option defaults to `""`) that would mask attr-path typos. Fix: drop the `or ""`, effort: S
- [x] **[MINOR]** `modules/common.nix:1`, unused `pkgs` module arg (same: unused `config` in `home/common/terminal/ghostty/default.nix:1`). Fix: reduce headers, effort: S

#### Docs drift

- [x] **[MINOR]** `docs/architecture.md:88`, HM tree puts oh-my-posh under `cli/` (lives in `shell/`), omits orca editor, core.nix, options.nix. Fix: regenerate the tree, effort: S
- [x] **[MINOR]** `docs/architecture.md:156`, links to README anchor `#adding-a-new-machine` which doesn't exist; the real guide is docs/adding-host-or-user.md. Fix: repoint, effort: S
- [x] **[MINOR]** `docs/architecture.md:31`, mkHost documented as taking four args; it also takes masApps/trustedTaps/extraShellUsers, and masApps is in live use. Fix: add rows, effort: S
- [x] **[MINOR]** `docs/ai-setup.md:204`, attributes the localSkills copy and customSkillsReconcile to init.nix; they live in lib/ai.nix and skills/default.nix. Fix: relabel, effort: S
- [x] **[MINOR]** `README.md:146`, work host row lists `packages` but the work host has no packages.nix. Fix: drop it, effort: S
- [x] **[MINOR]** `README.md:82`, prescribes the official Nix installer while recovery.md prescribes Determinate (which CI actually uses); the official one doesn't enable flakes. Fix: standardize on Determinate, effort: S

#### Security

- [x] **[MINOR]** `home/common/ai/init.nix:19`, `pipx install code-review-graph` unpinned from PyPI in activation, failure swallowed by `|| echo`, while `mcp.nix:18` unconditionally wires the binary as an always-on MCP server on both machines — a failed install leaves a permanently broken server; a hijacked release gets a seat in every session. Fix: pin a version or package via Nix; make mcp.nix conditional or fail loudly, effort: M
- [x] **[MINOR]** `home/common/ai/settings.nix:37`, `permissions.deny` protects secret paths from Read only; Bash `cat ~/.ssh/id_ed25519` is merely prompt-gated. Fix: add matching Bash deny patterns as defense in depth, effort: S
- [ ] **[MINOR]** `home/roles/work/ai/skills/local/acli/references/mp-conventions.md:1`, employer-internal Jira structure (project/board ids, custom fields) committed to a personal GitHub repo — one visibility flip from leaking. Fix: seed locally like git/private, or move to an employer-owned repo, effort: M — **deferred: needs owner's decision on where the data should live**
- [x] **[MINOR]** `home/common/ai/vault-context.sh:81`, cwd basename interpolated unescaped into the ripgrep pattern; regex metachars in a dir name mis-match vault notes. Fix: `rg -l --fixed-strings --line-regexp`, effort: S

#### Fish / shell

- [x] **[MINOR]** `home/common/shell/fish/functions.nix:37`, `commt` (and `review_commt:96`) chain `git add -A; git commit; git push` with `;` not `; and` — a failed commit still pushes. Fix: chain with `and`, effort: S
- [x] **[MINOR]** `home/common/shell/fish/functions.nix:111`, prompt string `"Delete (count $targets) dirs?"` — `(...)` doesn't expand inside double quotes in fish; prints garbage. Fix: `$(count $targets)`, effort: S
- [x] **[MINOR]** `home/common/shell/fish/functions.nix:12`, `goBranch` runs `git checkout "$argv"` — quoted list joins with spaces; no arg-count guard. Fix: `$argv[1]` + guard, effort: S
- [x] **[MINOR]** `home/common/shell/fish/functions.nix:149`, `doppler_safe` ships to both hosts but doppler is installed only on macbook. Fix: move to the personal role or guard with `command -q doppler`, effort: S
- [x] **[MINOR]** `home/common/shell/fish/abbrs.nix:197`, all 16 `git flow` abbreviations reference a git-flow binary installed nowhere — every one fails on both hosts. Fix: delete the block or install git-flow, effort: S
- [x] **[MINOR]** `home/common/shell/fish/default.nix:46`, `fzf_preview_dir_cmd` is a fzf.fish-plugin variable but that plugin isn't installed; the setting is dead. Fix: drop it or use programs.fzf options, effort: S
- [x] **[MINOR]** `home/roles/work/fish/default.nix:3`, gcloud PATH added only in interactiveShellInit (absent from scripts/`fish -c`) and PREPENDED ahead of Nix-managed PATH. Fix: shellInit + `--append`, effort: S

#### AI setup

- [x] **[MINOR]** `home/common/ai/instructions/learned-rules.md:20`, machine-wide rule names `personal-stack`, a skill that exists only on the personal role — every work session carries a pointer to a nonexistent skill (scoping-rule violation). Fix: role-neutral phrasing or move to role instructions, effort: S
- [x] **[MINOR]** `home/common/ai/skills/local/open-pr/SKILL.md:46`, machine-wide skill uses the work Jira key `MP-1234` as its example, violating "never name a specific project in a machine-wide skill". Fix: neutral `ABC-123`, effort: S
- [x] **[MINOR]** `home/common/ai/delegate-nudge.sh:20`, counter keys on `.prompt_id // .session_id`; when prompt_id is absent the "per-turn" nudge silently becomes once-per-2-hours-per-session, contradicting its own header and delegation.md. Fix: verify the field, or exit 0 when missing, effort: M — **no change needed: `prompt_id` is a documented hook-input field (verified against code.claude.com/docs/en/hooks), so the fallback is a non-issue**
- [x] **[MINOR]** `lib/ai.nix:53`, three mkLocalSkills instances copy into the same `~/.claude/skills/<name>` with no cross-label uniqueness assertion; a duplicate name deploys whichever activation ran last (DAG order unspecified). Fix: assert no duplicates in merged customSkills, effort: S
- [x] **[MINOR]** `home/common/ai/agents/default.nix:2`, comment says role agents live in `home/roles/<role>/ai/agents/local/` but no role wires mkLocalAgents — a file placed there silently never deploys, with no assertion to catch it. Fix: fix the comment or wire the roles, effort: S

#### Scripts + CI

- [x] **[MINOR]** `nix.sh:557`, nothing ever invokes `deploy-doctor.sh` even though docs/nix-conventions.md calls it mandatory before applying — the guard against silent deletions is opt-in memory. Fix: call it from `nix.sh` before `apply_config` (prompt to continue), effort: S
- [x] **[MINOR]** `scripts/deploy-doctor.sh:44`, found during fix mode: the eval attr path interpolated `$USER_NAME` unquoted, so the dotted work username (`daniel.a.sousa`) parsed as nested attrs and the doctor always aborted on the work config. Fix: quote the attr segment, effort: S
- [x] **[MINOR]** `nix.sh:287`, `core.hooksPath .hooks` is set only when `nix.sh` runs from the repo — on a fresh clone, commits before the first deploy skip `nix fmt` and `verify-plugins.sh` entirely. Fix: document it, or set hooksPath via HM's git config for this repo, effort: S
- [x] **[MINOR]** `nix.sh:396`, `clear_hm_backups` unconditionally deletes every `*.backup` under `~/.config` and `~/.claude` — files HM created because content collided, i.e. the only copy of that content — and it skips entirely on the work host's split-account setup, where the failure it guards against actually occurs. Fix: move backups to a dated stash dir instead of `rm -f`, and handle the other-user path, effort: M
- [x] **[MINOR]** `.hooks/pre-commit:8`, gates on bare `git diff --quiet` over all tracked files, so any pre-existing unstaged change aborts every commit with a false "nix fmt made changes" — training the habit of `--no-verify`, which also skips the plugin check. Fix: diff only the staged .nix files, effort: M
- [x] **[MINOR]** `nix.sh:45`, the INT/TERM trap doesn't restore terminal state from `_tui_select` — Ctrl-C in the picker leaves the shell with echo off until `reset`. Fix: `stty sane` + `\033[?25h\033[?7h` in `_cleanup`, effort: S
- [x] **[MINOR]** `scripts/deploy-doctor.sh:94`, jq reads of live settings.json are `2>/dev/null` with no validation — a corrupt settings.json (or missing jq, a stated but unchecked dep) yields a false all-clear from the tool whose job is catching silent deletions. Fix: `command -v jq` + `jq empty` guards that abort loudly, effort: S
- [x] **[MINOR]** `scripts/verify-plugins.sh:108`, failed `git show > "$mj"` leaves an empty file, so later plugins from the same marketplace get a misleading "not a plugin in repo" instead of "no marketplace.json". Fix: `rm -f "$mj"` in the failure branch, effort: S
- [x] **[MINOR]** `scripts/darwin/install-mas-apps.sh:20`, `mas list | grep -q` under pipefail can SIGPIPE-fail on a found app, causing a spurious reinstall + "failed to install" warning. Fix: capture `mas list` once and grep the variable, effort: S
- [x] **[MINOR]** `scripts/darwin/fix-fish-shell.sh:28`, the store-path fallback shell is never `-x`-checked and /etc/shells registration only covers `$fish_bin` — dscl can set a nonexistent, unregistered login shell. Fix: gate the dscl write on `[ -x "$target_shell" ]`, effort: S

## Council (haiku + sonnet + opus)

Advisors: contrarian (opus), first-principles (sonnet), expansionist (haiku), outsider (haiku), executor (sonnet); blind peer review and chairman on opus.

### Chairman's recommendation

> **Stop adding machinery and start subtracting, beginning with the supply chain.** Ten third-party marketplaces are declared as bare `owner/repo` with no ref — they execute at HEAD, on the work laptop, alongside client repos and Jira credentials, while nixpkgs is hash-pinned. Same class: `init.nix` runs `pipx install code-review-graph` unpinned in activation and swallows the failure, leaving `mcp.nix` pointing at a binary that may not exist.
>
> **The single most important reason:** every other guardrail in this repo — build-time assertions, deploy-doctor, flake check, Renovate gating — protects against drift you cause yourself, which is recoverable. The unpinned marketplaces are the only path where someone else's commit runs on your work machine unreviewed.
>
> **Today:** open `home/common/ai/plugins.nix` and, for each marketplace, either delete it (if you can't name a skill you actually invoke from it) or pin it to a reviewed commit. Expect to delete most. Then delete the `pipx` block in `init.nix` and the MCP server that depends on it. Second pass: make `nix.sh` call `deploy-doctor.sh` automatically.

### Peer review highlights

- **Strongest response:** the contrarian (opus) — the only advisor who found verified defects rather than describing architecture; the marketplace-pinning asymmetry was "the single most important finding anyone made". Runner-up: the executor (sonnet), for the confirmed facts that nothing calls `deploy-doctor.sh` and there is no rollback story in `nix.sh`.
- **Biggest blind spot:** the expansionist (haiku) — answered an over-engineering question with five new subsystems and was "the only response that would make the setup strictly worse if followed". The outsider (haiku) made confident claims that were already handled (`result` is gitignored; secrets are gitignored by design).
- **What everyone missed:** (1) the AI layer's cost is per-session, not per-deploy — ~20 skills + 18 plugins load into every session's context, and nobody asked whether the layer is net-positive *in use* (cheapest experiment: disable half for two weeks); (2) the pre-commit hook doesn't exist on a fresh clone; (3) the hook's false positive trains `--no-verify` habits; (4) nobody evaluated the bootstrap/disaster-recovery path or checked whether `~/.claude.json` has already drifted from the declared MCP set; (5) the highest-leverage move is deletion, not fixing.
