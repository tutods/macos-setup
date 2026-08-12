# ── Claude Code plugin marketplaces — shared across every host ────────────────
#
# All non-custom skills are installed as plugins. Claude Code reads
# `extraKnownMarketplaces` + `enabledPlugins` out of ~/.claude/settings.json
# (written by ./settings.nix) and installs on next launch — there is no sync
# script and nothing to run by hand.
#
# `claude-plugins-official` ships with Claude Code, so it needs no marketplace
# entry — only its plugins are listed below.
#
# Custom, in-repo skills do NOT come from here — see skills/default.nix.
#
# ── Adding a source ───────────────────────────────────────────────────────────
# Plugins are coarser than skills: enabling one registers *every* skill it
# ships, and a plugin's bundled .mcp.json registers its MCP servers too. Check
# both before adding, and prefer single-skill plugins:
#
#   scripts/verify-plugins.sh          # every declared plugin resolves + skill counts
#
# Find the plugin whose `source` dir holds the `skills/<name>/` you want in the
# repo's .claude-plugin/marketplace.json. Repos without that file cannot be
# installed this way — see docs/dropped-skill-sources.md.
#
{...}: {
  home.ai.marketplaces = {
    caveman = "JuliusBrussee/caveman";
    impeccable = "pbakaus/impeccable";
    anthropic-agent-skills = "anthropics/skills";
    mattpocock = "mattpocock/skills";
    humanizer = "blader/humanizer";
    knowledge-work-plugins = "anthropics/knowledge-work-plugins";
    claude-code-workflows = "wshobson/agents";
    claude-skills = "secondsky/claude-skills";
    # Single-skill plugins only — see the two entries in home.ai.plugins.
    claude-code-skills = "alirezarezvani/claude-skills";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "github@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "figma@claude-plugins-official"
    "claude-code-setup@claude-plugins-official" # Claude Code config, incl. agent authoring

    # ── authoring skills and agents ─────────────────────────────────────────
    "example-skills@anthropic-agent-skills" # skill-creator, mcp-builder (+10 others)
    "write-a-skill@claude-code-skills" # 1 skill

    # ── single-plugin marketplaces ──────────────────────────────────────────
    "caveman@caveman"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"

    # ── wshobson/agents ─────────────────────────────────────────────────────
    "javascript-typescript@claude-code-workflows" # nodejs-backend, modern-js, ts-advanced-types, js-testing
    "developer-essentials@claude-code-workflows" # error-handling / auth-implementation / nx / turborepo
    "backend-development@claude-code-workflows" # api-design, architecture, cqrs, microservices — NestJS-adjacent
    "cicd-automation@claude-code-workflows" # deployment-pipeline, github-actions, secrets-management

    # ── anthropics/knowledge-work-plugins ───────────────────────────────────
    "design@knowledge-work-plugins" # accessibility-review, ux-copy, design-critique

    # ── secondsky/claude-skills (one plugin per skill) ──────────────────────
    "react-hook-form-zod@claude-skills"
    "rest-api-design@claude-skills"
    "csrf-protection@claude-skills"
    "health-check-endpoints@claude-skills"
    "xss-prevention@claude-skills"
    "systematic-debugging@claude-skills"
  ];
}
