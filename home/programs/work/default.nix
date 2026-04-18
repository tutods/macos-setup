# Work-only program configuration.
# Imported via mkUser extraImports for daniel.a.sousa.
# Add work-specific overrides here (e.g. work Fish aliases, work VSCode extensions).
{config, ...}: {
  programs.vscode.profiles.default.userSettings."yaml.schemas" = {
    "file://${config.home.homeDirectory}/.vscode/extensions/atlassian.atlascode-3.0.10/resources/schemas/pipelines-schema.json" = "bitbucket-pipelines.yml";
  };
}
