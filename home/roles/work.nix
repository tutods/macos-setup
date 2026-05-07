{config, ...}: {
  programs.vscode.profiles.default.userSettings."yaml.schemas" = {
    "file://${config.home.homeDirectory}/.vscode/extensions/atlassian.atlascode-3.0.10/resources/schemas/pipelines-schema.json" = "bitbucket-pipelines.yml";
  };
}
