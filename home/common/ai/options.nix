{lib, ...}: {
  options.home.ai = {
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    vaultFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["Conventions" "Lessons" "Decisions" "Process" "Projects" "Clients" "Notes"];
      description = ''
        Vault folders in scope for this machine, exported as the
        CLAUDE_VAULT_FOLDERS env var in settings.json; the vault-lint agent
        audits folder coverage against it. Scope this per role: the work
        machine must not declare personal-context folders (freelance clients,
        personal projects). The vault stays readable either way, this only
        declares the scope.
      '';
    };

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {caveman = "JuliusBrussee/caveman@df2ccd85c94ec3c8289cb62ac020d241ccfb0c60";};
      description = ''
        Claude Code plugin marketplaces, as `<key> = "<owner>/<repo>[@<commit sha>]"`.
        The key is chosen here (not read from the repo) and used in
        `home.ai.plugins` as `<plugin>@<key>`; renaming it orphans
        already-installed plugins. The optional `@<sha>` pins the marketplace to
        a reviewed commit instead of HEAD; third-party marketplaces must be
        pinned (their skills execute locally, this is the supply chain).
        `claude-plugins-official` is built in, do not list it.
      '';
    };

    customSkills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      internal = true;
      description = ''
        Names of skills copied into ~/.claude/skills from in-repo sources.
        Populated by `lib/ai.nix:mkLocalSkills`; skills/default.nix reads it
        to report directories in ~/.claude/skills that this repo doesn't own.
      '';
    };

    externallyManagedSkills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["orca-cli" "orchestration" "computer-use"];
      description = ''
        Names of skill dirs in ~/.claude/skills NOT managed by this flake
        (installed and updated by external tools, e.g. Orca's own updater).
        `customSkillsReconcile` leaves these alone instead of deleting them as
        unmanaged, and deploy-doctor.sh excludes them from its unmanaged-skill
        warnings.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["caveman@caveman"];
      description = ''
        Plugins to enable, as `<plugin>@<marketplace>`. Every non-custom skill
        arrives this way; custom in-repo skills are deployed by skills/default.nix.
      '';
    };
  };
}
