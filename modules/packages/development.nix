{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    claude-code
    opencode
    terraform
    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
