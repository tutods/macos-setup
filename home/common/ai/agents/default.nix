# In-repo subagents, shared across every role. External agents come bundled
# inside plugins. Role-specific agents are not wired yet: a role wanting one
# must import aiLib.mkLocalAgents in its ai/default.nix (files dropped into a
# roles agents dir without that import silently never deploy).
{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalAgents {
      inherit lib;
      dir = ./local;
      names = ["vault-lint" "vault-search"];
    })
  ];
}
