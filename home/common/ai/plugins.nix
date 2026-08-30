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
    impeccable = "pbakaus/impeccable@b0594c72d18006b5865c70eb3a97e8b04064e600";
    mattpocock = "mattpocock/skills@6654f6b60cd9d5be8b54c6fafe44346dabeb3b76";
    humanizer = "blader/humanizer@e2e92e7b4b8229253ed5c8e81dc65463fdeddda5";
    ponytail = "DietrichGebert/ponytail@2ed6c52c9d7e5e56942508591085fd45dea277d3";
    claude-code-skills = "alirezarezvani/claude-skills@19392f7a08264ed00486a251f5b2098321771f94";
    ui-ux-pro-max-skill = "nextlevelbuilder/ui-ux-pro-max-skill@8bd29e775453ebcae52b6e6514fbf134df0c5770";
    frontend-slides = "zarazhangrui/frontend-slides@9906a34d640d2111f724544cbc50f7f130569ae1";
    claude-video = "bradautomates/claude-video@83da59fa78c3eee9e20f515fe75c438bb5166efd";
    addy-web-quality-skills = "addyosmani/web-quality-skills@afa8da942115f2961fdbfa80807ea0b232ff6c00";
    ai-builder-club = "AI-Builder-Club/skills@d4cd90f5915b10412595733a0fbdca96f65115b1";
  };

  home.ai.plugins = [
    # ── claude-plugins-official (built in) ──────────────────────────────────
    "superpowers@claude-plugins-official"
    "code-review@claude-plugins-official"
    "github@claude-plugins-official"
    "claude-code-setup@claude-plugins-official" # Claude Code config, incl. agent authoring
    "playwright@claude-plugins-official" # browser automation / e2e MCP, generic across web projects
    "frontend-design@claude-plugins-official"
    "typescript-lsp@claude-plugins-official" # TS language server for code intelligence
    "figma@claude-plugins-official" # design context, tokens, Code Connect, design-to-code

    # ── authoring skills and agents ───────────────────────────────────────
    "write-a-skill@claude-code-skills" # also ships the cs-skill-author agent

    # ── one plugin per marketplace ─────────────────────────────────────────
    "caveman@caveman"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement, generic
    "ui-ux-pro-max@ui-ux-pro-max-skill" # UI/UX rule database, incl. the shadcn and Tailwind stacks
    "frontend-slides@frontend-slides" # zero-dependency HTML deck generator
    "watch@claude-video" # yt-dlp download + video analysis
    "web-quality-skills@addy-web-quality-skills" # Lighthouse-category audits, GEO/SEO baseline
    "skills@ai-builder-club" # codebase harness + loop engineer (10 skills), generic
  ];
}
