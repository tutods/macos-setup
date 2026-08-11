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
# Adding a source: plugins are coarser than skills. Find the plugin that ships
# the skill you want in the repo's .claude-plugin/marketplace.json (a plugin's
# `source` dir contains the `skills/<name>/` you're after), then add the
# marketplace and the plugin. Repos without a .claude-plugin/marketplace.json
# cannot be installed this way — see docs/dropped-skill-sources.md.
#
{...}: {
  home.ai.marketplaces = {
    caveman = "JuliusBrussee/caveman";
    # Key kept as-is (repo declares "agricidaniel-claude-seo") — renaming would
    # orphan the already-installed plugin.
    agricidaniel-seo = "AgriciDaniel/claude-seo";
    impeccable = "pbakaus/impeccable";
    anthropic-agent-skills = "anthropics/skills";
    mattpocock = "mattpocock/skills";
    humanizer = "blader/humanizer";
    knowledge-work-plugins = "anthropics/knowledge-work-plugins";
    claude-code-workflows = "wshobson/agents";
    claude-skills = "secondsky/claude-skills";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "code-simplifier@claude-plugins-official"
    "github@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "commit-commands@claude-plugins-official"
    "figma@claude-plugins-official"
    "claude-code-setup@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "sourcegraph@claude-plugins-official"
    "prisma@claude-plugins-official"
    "sanity@claude-plugins-official"

    # ── single-plugin marketplaces ──────────────────────────────────────────
    "caveman@caveman"
    "claude-seo@agricidaniel-seo"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"

    # ── anthropics/skills ───────────────────────────────────────────────────
    "example-skills@anthropic-agent-skills" # mcp-builder, skill-creator

    # ── anthropics/knowledge-work-plugins ───────────────────────────────────
    "engineering@knowledge-work-plugins" # system-design
    "product-management@knowledge-work-plugins" # write-spec
    "design@knowledge-work-plugins" # accessibility-review, ux-copy

    # ── wshobson/agents ─────────────────────────────────────────────────────
    "backend-development@claude-code-workflows" # architecture-patterns
    "cicd-automation@claude-code-workflows" # deployment-pipeline-design
    "ui-design@claude-code-workflows" # design-system-patterns
    "developer-essentials@claude-code-workflows" # error-handling / auth-implementation / nx-workspace patterns
    "framework-migration@claude-code-workflows" # database-migration, dependency-upgrade
    "agent-teams@claude-code-workflows" # multi-reviewer, parallel-debugging, parallel-feature-development, team-composition, team-communication

    # ── secondsky/claude-skills (one plugin per skill) ──────────────────────
    "react-hook-form-zod@claude-skills"
    "rest-api-design@claude-skills"
    "csrf-protection@claude-skills"
    "health-check-endpoints@claude-skills"
    "xss-prevention@claude-skills"
    "systematic-debugging@claude-skills"
    "image-optimization@claude-skills"
  ];
}
