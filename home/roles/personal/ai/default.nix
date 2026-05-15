let
  instructions = builtins.readFile ./instructions.md;

  # Helper to simplify MCP server definition
  mkMcp = {
    cmd,
    args,
  }: {
    command = cmd;
    args = args;
  };
in {
  home.ai.extraInstructions = instructions;

  home.ai.extraSkillsManifest = builtins.readFile ./skills/manifest.txt;

  home.ai.extraMcpServers = {
    docker = mkMcp {
      cmd = "docker";
      args = ["mcp" "gateway" "run"];
    };
    postgres = mkMcp {
      cmd = "sh";
      args = ["-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
    };
    shadcn = mkMcp {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}
