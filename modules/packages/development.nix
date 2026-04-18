{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    claude-code
    opencode
  ];
}
