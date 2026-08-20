# Plugin marketplaces shared across every host. Generic plugins only,
# stack- and domain-specific ones are enabled per project.
# How to add one, and why they fail silently: docs/ai-setup.md.
# Run scripts/verify-plugins.sh after every change here.
#
# Prune by marketplace, not by skill: the marketplace is the config unit, so a
# skill cannot be dropped on its own.
{...}: {
  home.ai.marketplaces = {
    caveman = "JuliusBrussee/caveman";
    impeccable = "pbakaus/impeccable";
    anthropic-agent-skills = "anthropics/skills";
    mattpocock = "mattpocock/skills";
    humanizer = "blader/humanizer";
    claude-code-skills = "alirezarezvani/claude-skills";
    ponytail = "DietrichGebert/ponytail";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "code-review@claude-plugins-official"
    "github@claude-plugins-official"
    "feature-dev@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "claude-code-setup@claude-plugins-official" # Claude Code config, incl. agent authoring
    "playwright@claude-plugins-official" # browser automation / e2e MCP, generic across web projects

    # ── authoring skills and agents ─────────────────────────────────────────
    "example-skills@anthropic-agent-skills" # skill-creator, mcp-builder (+10 others)
    "write-a-skill@claude-code-skills" # also ships the cs-skill-author agent

    # ── single-plugin marketplaces ──────────────────────────────────────────
    "caveman@caveman"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement, generic
  ];
}
