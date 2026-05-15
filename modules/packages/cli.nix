{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mkalias
    duf
    fd
    fnm
    httpie
    jq
    qpdf
    ripgrep
    smartmontools
    speedtest-cli
    tldr
    libwebp # cwebp / dwebp CLI tools
    yt-dlp
  ];
}
