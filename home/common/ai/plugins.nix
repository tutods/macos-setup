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
    ui-ux-pro-max-skill = "nextlevelbuilder/ui-ux-pro-max-skill";
    frontend-slides = "zarazhangrui/frontend-slides";
    claude-code-workflows = "wshobson/agents";
    social-media-skills = "charlie947/social-media-skills";
    claude-video = "bradautomates/claude-video";
    addy-web-quality-skills = "addyosmani/web-quality-skills";
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
    "code-simplifier@claude-plugins-official" # simplify-recent-changes agent
    "pr-review-toolkit@claude-plugins-official" # granular PR-review agents (types, error handling)
    "frontend-design@claude-plugins-official"
    "project-artifact@claude-plugins-official" # living project status page as an artifact
    "claude-md-management@claude-plugins-official" # audit CLAUDE.md, capture session learnings
    "typescript-lsp@claude-plugins-official" # TS language server for code intelligence
    "figma@claude-plugins-official" # design context, tokens, Code Connect, design-to-code

    # ── authoring skills and agents ─────────────────────────────────────────
    "example-skills@anthropic-agent-skills" # skill-creator, mcp-builder (+10 others)
    "write-a-skill@claude-code-skills" # also ships the cs-skill-author agent

    # ── one plugin per marketplace ─────────────────────────────────────────
    "caveman@caveman"
    "impeccable@impeccable"
    "mattpocock-skills@mattpocock"
    "humanizer@humanizer"
    "ponytail@ponytail" # lazy-senior-dev / YAGNI enforcement, generic
    "ui-ux-pro-max@ui-ux-pro-max-skill" # UI/UX rule database, incl. the shadcn and Tailwind stacks
    "frontend-slides@frontend-slides" # zero-dependency HTML deck generator
    "social-media-skills@social-media-skills" # LinkedIn / IG / YouTube content production
    "watch@claude-video" # yt-dlp download + video analysis
    "web-quality-skills@addy-web-quality-skills" # Lighthouse-category audits, GEO/SEO baseline

    # ── large marketplaces, one plugin enabled ────────────────────────────
    "developer-essentials@claude-code-workflows" # wshobson/agents (~95 plugins); only this one
  ];
}
