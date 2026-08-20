# In-repo subagents, shared across every role. External agents come bundled
# inside plugins. Role-specific agents live in home/roles/<role>/ai/agents/local/.
{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalAgents {
      inherit lib;
      dir = ./local;
      names = [
        "code-reviewer"
        "dev-lifecycle"
        "vault-lint"
        "vault-search"
      ];
    })
  ];
}
