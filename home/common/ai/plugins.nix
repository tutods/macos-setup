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
  # Machine-wide plugins are GENERIC ONLY — workflow, writing, debugging,
  # authoring. Anything stack- or domain-specific (framework packs, SEO,
  # design tooling) is enabled per project instead: committed
  # .claude/settings.json where the repo allows it, .claude/settings.local.json
  # in team/company repos and wherever settings.json is gitignored.
  home.ai.marketplaces = {
    caveman = "JuliusBrussee/caveman";
    impeccable = "pbakaus/impeccable";
    anthropic-agent-skills = "anthropics/skills";
    mattpocock = "mattpocock/skills";
    humanizer = "blader/humanizer";
    # Single-skill plugin, but also ships a distinct agent — see the entry
    # in home.ai.plugins.
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
    # systematic-debugging@claude-skills was dropped — it's a near-verbatim
    # fork of superpowers:systematic-debugging (same Iron Law, same phases).
    # write-a-skill@claude-code-skills is kept despite the name overlap with
    # superpowers:writing-skills — it also ships the cs-skill-author agent
    # (adversarial 6-question gate before accepting a new skill) and the
    # /cs:write-a-skill command, neither of which superpowers has.
    "example-skills@anthropic-agent-skills" # skill-creator, mcp-builder (+10 others)
    "write-a-skill@claude-code-skills"

    # ── single-plugin marketplaces ──────────────────────────────────────────
    "caveman@caveman"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement — generic
  ];
}
