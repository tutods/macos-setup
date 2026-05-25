{lib, ...}: {
  options.home.ai = {
    projectDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/Developer";
      description = "Primary project directory for development work (used in fish functions)";
    };

    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    extraMcpServers = lib.mkOption {
      default = {};
      description = "Role-specific MCP servers merged into both claude_desktop_config.json and opencode.json";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            description = "Command to launch the MCP server";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments passed to command";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Environment variables injected at server spawn";
          };
        };
      });
    };

    extraSkillsManifest = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra skill install lines appended to the common manifest, installed to both agents";
    };
  };
}
