{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    opencode
    ollama
    (pipx.overridePythonAttrs {doCheck = false;})
    rtk
    repomix
  ];
}
