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
    mattpocock = "mattpocock/skills";
    humanizer = "blader/humanizer";
    ponytail = "DietrichGebert/ponytail";
    claude-code-skills = "alirezarezvani/claude-skills";
    ui-ux-pro-max-skill = "nextlevelbuilder/ui-ux-pro-max-skill";
    frontend-slides = "zarazhangrui/frontend-slides";
    claude-video = "bradautomates/claude-video";
    addy-web-quality-skills = "addyosmani/web-quality-skills";
    ai-builder-club = "AI-Builder-Club/skills";
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
