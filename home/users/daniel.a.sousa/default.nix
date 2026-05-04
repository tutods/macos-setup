# Work user configuration.
# Imported via mkUser extraImports for daniel.a.sousa.
# Imports shared programs and adds work-specific overrides.
{config, ...}: {
  # imports = [../../shared/default.nix];

  programs.vscode.profiles.default.userSettings."yaml.schemas" = {
    "file://${config.home.homeDirectory}/.vscode/extensions/atlassian.atlascode-3.0.10/resources/schemas/pipelines-schema.json" = "bitbucket-pipelines.yml";
  };
}
