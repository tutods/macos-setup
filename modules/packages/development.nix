{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    opencode
    codex
    ollama
    pipx
    rtk
  ];
}
