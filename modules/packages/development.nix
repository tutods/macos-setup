{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    ollama
    (pipx.overridePythonAttrs {doCheck = false;})
    rtk
    repomix
  ];
}
