{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    opencode
    copilot-cli
    pipx
  ];
}
