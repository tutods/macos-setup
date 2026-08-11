{
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../lib/ai.nix {inherit pkgs;};
in {
  # Work-only custom skills — real dirs in ~/.claude/skills.
  # (Custom skills shared across roles live in ~/.dotfiles/skills/default.nix.)
  imports = [
    (ai.mkLocalSkills {
      inherit lib;
      label = "work";
      dir = ./skills/local;
      names = ["acli"];
    })
  ];

  home.ai.extraInstructions =
    ai.appendIfNonEmpty
    (builtins.readFile ./instructions.md)
    (builtins.readFile ../../../common/cli/ai/context/stack-work.md);

  # Requires in ~/.config/fish/secrets.fish:
  #   set -gx JIRA_URL       "https://<company>.atlassian.net"
  #   set -gx JIRA_EMAIL     "daniel.a.sousa@<company>.com"
  #   set -gx JIRA_API_TOKEN "<token from id.atlassian.com/manage-profile/security/api-tokens>"
  home.ai.extraMcpServers = {
    jira = ai.mkServer {
      cmd = "npx";
      args = ["-y" "mcp-atlassian"];
    };
  };

  # Work-only plugin marketplaces (Jira ticket management).
  home.ai.marketplaces = {
    claude-code-skills = "alirezarezvani/claude-skills";
  };

  home.ai.plugins = [
    "pm-skills@claude-code-skills" # jira-expert
  ];
}
