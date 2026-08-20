{
  aiLib,
  config,
  pkgs,
  lib,
  ...
}: let
  servers = import ./mcp-servers.nix {
    inherit pkgs;
    homeDir = config.home.homeDirectory;
  };

  # Nix-authoritative for ADDITIONS only — see the merge note below. Add
  # servers here, not via UI.
  #
  # `filesystem` was dropped — it was scoped to ~/.dotfiles and ~/Developer,
  # exactly where Claude Code's native Read/Glob/Grep already reach, so it only
  # added duplicate tool schemas to every session.
  #
  # `github` and `playwright` are defined in ./mcp-servers.nix but deliberately
  # NOT wired in here: `playwright@claude-plugins-official` already provides
  # playwright, and `github@claude-plugins-official` already provides GitHub
  # tools (this machine has no GITHUB_TOKEN set, so the hand-rolled github
  # server would spawn unauthenticated anyway). Wiring either back in would
  # reintroduce the duplicate-server problem this file was fixed for.
  allServers =
    {
      code-review-graph = servers.code-review-graph;
    }
    // config.home.ai.extraMcpServers;
in {
  # Claude Code reads user-scope MCP servers from `~/.claude.json`'s
  # `mcpServers` key — NOT from `~/.claude/claude_desktop_config.json` (that's
  # Claude Desktop's file, and Claude Code never reads it). Verify with
  # `claude mcp list`.
  #
  # `~/.claude.json` is live session state Claude Code writes to constantly
  # (it also holds servers added by hand, e.g. via `claude mcp add`), so this
  # MERGES into `mcpServers` instead of replacing it — replacing would delete
  # anything not declared here on the next deploy. The consequence: Nix is
  # authoritative for additions, not removals. Dropping a server from
  # `allServers` does NOT delete it from `~/.claude.json` — remove it once by
  # hand with `claude mcp remove <name> --scope user`.
  #
  # Deploy with no other Claude Code session running — a concurrent write to
  # `~/.claude.json` during this read-modify-write could be lost.
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary" "aiInit"] (
    aiLib.mergeJsonKey {
      file = "$HOME/.claude.json";
      key = "mcpServers";
      value = allServers;
      extraMerge = ''.mcpServers = (.mcpServers // {}) + $v'';
    }
  );
}
