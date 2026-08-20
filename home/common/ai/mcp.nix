{
  aiLib,
  config,
  lib,
  ...
}: let
  # Enabling a plugin also registers any MCP servers in its bundled .mcp.json,
  # so `claude mcp list` shows servers not declared here. Drop the plugin to
  # remove those, don't add a competing copy.
  allServers =
    {
      # Tree-sitter code graph, so review/impact questions query structure
      # instead of re-reading files. Not installed via `code-review-graph
      # install`, that writes hooks into ~/.claude/settings.json, which this
      # repo overwrites on every deploy. Per-repo `code-review-graph build` is
      # still required before its graph answers anything.
      code-review-graph = {
        command = "${config.home.homeDirectory}/.local/bin/code-review-graph";
        args = ["serve"];
      };
    }
    // config.home.ai.extraMcpServers;
in {
  # Claude Code reads user-scope servers from `~/.claude.json`'s `mcpServers`,
  # which it also writes to constantly, so this MERGES rather than replaces.
  # Nix is therefore authoritative for additions only: dropping a server here
  # does not remove it from the file (`claude mcp remove <name> --scope user`).
  # Deploy with no other Claude Code session running.
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary" "aiInit"] (
    aiLib.mergeJsonKey {
      file = "$HOME/.claude.json";
      key = "mcpServers";
      value = allServers;
      extraMerge = ''.mcpServers = (.mcpServers // {}) + $v'';
    }
  );
}
