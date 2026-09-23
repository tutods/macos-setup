{
  aiLib,
  lib,
  ...
}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # Merges into ~/.claude.json mcpServers, which Claude Code also writes; Nix adds, never removes.
  # Dropping a server here leaves it live: claude mcp remove <name> --scope user.
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
    aiLib.mergeJsonKey {
      file = "$HOME/.claude.json";
      key = "mcpServers";
      value = {
        shadcn = aiLib.mkServer {
          cmd = "npx";
          args = ["-y" "shadcn@latest" "mcp"];
        };
      };
      extraMerge = ''.mcpServers = (.mcpServers // {}) + $v'';
    }
  );
}
