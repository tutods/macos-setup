{
  aiLib,
  lib,
  ...
}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # Claude Code reads user-scope servers from `~/.claude.json`'s `mcpServers`,
  # which it also writes to constantly, so this MERGES rather than replaces.
  # Nix is therefore authoritative for additions only: dropping a server here
  # does not remove it from the file (`claude mcp remove <name> --scope user`).
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
