{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    (pipx.overridePythonAttrs {doCheck = false;})
    rtk
  ];
}
