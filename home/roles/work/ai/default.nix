let
  # Helper matching personal/ai/default.nix pattern
  mkMcp = {
    cmd,
    args,
  }: {
    command = cmd;
    args = args;
  };
in {
  home.ai.extraInstructions =
    builtins.readFile ./instructions.md
    + "\n\n"
    + builtins.readFile ../../../common/cli/ai/context/stack-work.md;

  # Requires in ~/.config/fish/secrets.fish:
  #   set -gx JIRA_URL       "https://<company>.atlassian.net"
  #   set -gx JIRA_EMAIL     "daniel.a.sousa@<company>.com"
  #   set -gx JIRA_API_TOKEN "<token from id.atlassian.com/manage-profile/security/api-tokens>"
  home.ai.extraMcpServers = {
    jira = mkMcp {
      cmd = "npx";
      args = ["-y" "mcp-atlassian"];
    };
  };
}
