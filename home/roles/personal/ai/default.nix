{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "personal";
      dir = ./skills/local;
      names = ["optimize-images" "personal-stack"];
    })
  ];

  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  home.ai.extraMcpServers = {
    shadcn = aiLib.mkServer {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}
