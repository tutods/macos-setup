let
  instructions = builtins.readFile ./instructions.md;
in {
  home.ai.extraInstructions = instructions;

  home.ai.extraSkillsManifest = builtins.readFile ./skills/manifest.txt;

  home.ai.extraMcpServers = {
    docker = {
      command = "docker";
      args = ["mcp" "gateway" "run"];
    };
    postgres = {
      command = "sh";
      args = ["-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
    };
    shadcn = {
      command = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}
