{pkgs, ...}: let
  ai = import ../../../../lib/ai.nix {inherit pkgs;};
in {
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

  # Work-only AI skills (Storybook is used in work projects; Jira for ticket management)
  home.ai.extraSkillsManifest = ''
    oakoss/agent-skills -s storybook-stories
    morphet81/cheat-sheets -s create-jira-ticket -s update-jira-ticket
    alirezarezvani/claude-skills -s jira-expert
    arjunmahishi/dotfiles -s acli-jira
  '';
}
