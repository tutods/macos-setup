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
      names = ["elementor-crocoblock" "optimize-images"];
    })
  ];

  # Temporary — Kimi Code CLI, remove when done trying it out.
  home.packages = [
    (pkgs.writeShellScriptBin "kimi" ''
      exec ${pkgs.nodejs}/bin/npx -y @moonshot-ai/kimi-code@latest "$@"
    '')
  ];

  home.ai.extraInstructions =
    ai.appendIfNonEmpty
    (builtins.readFile ./instructions.md)
    (builtins.readFile ../../../common/cli/ai/context/stack-personal.md);

  # Personal-only plugin marketplaces. See
  # home/common/cli/ai/tools/claude/plugins.nix for the shared set.
  home.ai.marketplaces = {
    better-auth-agent-skills = "better-auth/skills";
    marketingskills = "coreyhaines31/marketingskills";
    addy-web-quality-skills = "addyosmani/web-quality-skills";
    social-media-skills = "charlie947/social-media-skills";
    hyperframes = "heygen-com/hyperframes";
    claude-video = "bradautomates/claude-video";
    ui-ux-pro-max-skill = "nextlevelbuilder/ui-ux-pro-max-skill";
    frontend-slides = "zarazhangrui/frontend-slides";
  };

  home.ai.plugins = [
    "auth-skills@better-auth-agent-skills"
    "marketing-skills@marketingskills"
    "web-quality-skills@addy-web-quality-skills"
    "social-media-skills@social-media-skills"
    "hyperframes@hyperframes"
    "core-skills@hyperframes"
    "watch@claude-video"
    "ui-ux-pro-max@ui-ux-pro-max-skill"
    "frontend-slides@frontend-slides"

    # wshobson/agents — marketplace declared in the shared plugins.nix
    "database-design@claude-code-workflows" # postgresql
    "hr-legal-compliance@claude-code-workflows" # gdpr-data-handling

    # anthropics/knowledge-work-plugins — ditto
    "brand-voice@knowledge-work-plugins" # brand-voice-enforcement
    "marketing@knowledge-work-plugins" # content-creation
  ];

  home.ai.extraMcpServers = {
    postgres = ai.mkServer {
      cmd = "sh";
      args = ["-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
    };
    shadcn = ai.mkServer {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}
