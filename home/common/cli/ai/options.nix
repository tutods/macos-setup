{lib, ...}: {
  options.home.ai = {
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    extraMcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Role-specific MCP servers merged into both claude_desktop_config.json and opencode.json";
    };

    extraSkillsManifest = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra skill install lines appended to the common manifest, installed to both agents";
    };
  };
}
