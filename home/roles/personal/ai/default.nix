{
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../lib/ai.nix {inherit pkgs;};
in {
  # Personal-only custom skills — real dirs in ~/.claude/skills.
  # (Custom skills shared across roles live in ~/.dotfiles/skills/default.nix.)
  imports = [
    (ai.mkLocalSkills {
      inherit lib;
      label = "personal";
      dir = ./skills/local;
      names = ["elementor-crocoblock" "optimize-images" "personal-stack"];
    })
  ];

  # Temporary — Kimi Code CLI, remove when done trying it out.
  home.packages = [
    (pkgs.writeShellScriptBin "kimi" ''
      exec ${pkgs.nodejs}/bin/npx -y @moonshot-ai/kimi-code@latest "$@"
    '')
  ];

  # Stack reference is the `personal-stack` skill above, not an always-on
  # instruction — it is irrelevant during Nix or content work.
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # Personal-only plugin marketplaces. See
  # home/common/cli/ai/tools/claude/plugins.nix for the shared set.
  home.ai.marketplaces = {
    better-auth-agent-skills = "better-auth/skills";
    addy-web-quality-skills = "addyosmani/web-quality-skills";
    social-media-skills = "charlie947/social-media-skills";
    claude-video = "bradautomates/claude-video";
    ui-ux-pro-max-skill = "nextlevelbuilder/ui-ux-pro-max-skill";
    frontend-slides = "zarazhangrui/frontend-slides";
    # Moved off the shared set — 31 SEO skills have no place on the work laptop.
    agricidaniel-seo = "AgriciDaniel/claude-seo";
  };

  home.ai.plugins = [
    "claude-seo@agricidaniel-seo" # 31 skills — the single SEO source
    "social-media-skills@social-media-skills" # 17 — Instagram/post work
    "ui-ux-pro-max@ui-ux-pro-max-skill" # 7
    "web-quality-skills@addy-web-quality-skills" # 6 — Core Web Vitals, perf, a11y
    "auth-skills@better-auth-agent-skills" # 2
    "watch@claude-video" # 1
    "frontend-slides@frontend-slides" # 1

    # wshobson/agents — marketplace declared in the shared plugins.nix
    "database-design@claude-code-workflows" # postgresql
    "hr-legal-compliance@claude-code-workflows" # gdpr-data-handling

    # anthropics/knowledge-work-plugins — ditto
    "marketing@knowledge-work-plugins" # 8 — the one marketing source
  ];

  # postgres dropped — @modelcontextprotocol/server-postgres was archived
  # upstream, and it only ever did read-only queries + schema inspection.
  # `doppler run -- psql` covers that without a stale server in the loop.
  home.ai.extraMcpServers = {
    shadcn = ai.mkServer {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}
