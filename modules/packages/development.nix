{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    opencode
    codex
    ollama
    pipx
    rtk
    repomix # pack repo into AI-readable file (repomix --output /tmp/ctx.md)
  ];
}
