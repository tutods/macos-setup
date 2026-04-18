{lib, ...}: {
  home.username = "daniel.a.sousa";
  home.homeDirectory = lib.mkForce "/Users/daniel.a.sousa";
  home.stateVersion = "23.11";

  imports = [
    ../programs
  ];

  programs.vscode.profiles.default.userSettings."yaml.schemas" = {
    "file:///Users/danielsousa/.vscode/extensions/atlassian.atlascode-3.0.10/resources/schemas/pipelines-schema.json" = "bitbucket-pipelines.yml";
  };
}
