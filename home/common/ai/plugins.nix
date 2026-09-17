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
    ai-builder-club = "AI-Builder-Club/skills@d4cd90f5915b10412595733a0fbdca96f65115b1";
    frontend-slides = "zarazhangrui/frontend-slides@9906a34d640d2111f724544cbc50f7f130569ae1";
    impeccable = "pbakaus/impeccable@0a4e72a254f3b175c95b36b82e5f2e60fa63f116";
    taste-skill = "leonxlnx/taste-skill@ccbc15639c97057cbfcf32ecebc38ef716e4bb37";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "code-review@claude-plugins-official"
    "claude-code-setup@claude-plugins-official" # Claude Code config, incl. agent authoring
    "figma@claude-plugins-official" # design context, tokens, Code Connect, design-to-code
    "frontend-design@claude-plugins-official" # UI/UX design critique and iteration guidance

    # ── one plugin per marketplace ─────────────────────────────────────────
    "caveman@caveman"
    "mattpocock-skills@mattpocock"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement, generic
    "web-quality-skills@addy-web-quality-skills" # Lighthouse-category audits, GEO/SEO baseline
    "skills@ai-builder-club" # codebase harness + loop engineer (10 skills), generic
    "frontend-slides@frontend-slides" # HTML presentation generator, PPT conversion
    "impeccable@impeccable" # frontend design fluency, polish/audit/critique commands
    "taste-skill@taste-skill" # frontend design taste skills (brutalist, minimalist, etc.)
  ];
}
