{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    opencode
    copilot-cli
    ollama
    pipx
  ];
}
