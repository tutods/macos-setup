# Plugin marketplaces shared across every host. Generic plugins only,
# stack- and domain-specific ones are enabled per project.
# How to add one, and why they fail silently: docs/ai-setup.md.
# Run scripts/verify-plugins.sh after every change here.
#
# Prune by marketplace, not by skill: the marketplace is the config unit, so a
# skill cannot be dropped on its own.
#
# Every third-party marketplace is pinned to a reviewed commit (`@<sha>`):
# these are strangers' repos whose skills execute locally, so unpinned HEAD
# would be the one supply chain nothing in this flake locks. Bump a pin only
# after reviewing the diff: `git ls-remote https://github.com/<owner>/<repo> HEAD`.
{...}: {
  home.ai.marketplaces = {
    caveman = "JuliusBrussee/caveman@df2ccd85c94ec3c8289cb62ac020d241ccfb0c60";
    mattpocock = "mattpocock/skills@6654f6b60cd9d5be8b54c6fafe44346dabeb3b76";
    ponytail = "DietrichGebert/ponytail@2ed6c52c9d7e5e56942508591085fd45dea277d3";
    addy-web-quality-skills = "addyosmani/web-quality-skills@afa8da942115f2961fdbfa80807ea0b232ff6c00";
    frontend-slides = "zarazhangrui/frontend-slides@9906a34d640d2111f724544cbc50f7f130569ae1";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "code-review@claude-plugins-official"
    # figma is enabled for Claude Code only, not bridged into opencode: see
    # opencodeBridgeExclude (home/roles/personal/opencode/default.nix) and
    # docs/opencode-setup.md. 42 skills, ~6.9k tokens across both harnesses,
    # zero skill loads recorded.
    "figma@claude-plugins-official" # design context, tokens, Code Connect, design-to-code

    # ── one plugin per marketplace ─────────────────────────────────────────
    "caveman@caveman"
    "mattpocock-skills@mattpocock"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement, generic
    "web-quality-skills@addy-web-quality-skills" # Lighthouse-category audits, GEO/SEO baseline
    "frontend-slides@frontend-slides" # HTML presentation generator, PPT conversion
  ];
}
