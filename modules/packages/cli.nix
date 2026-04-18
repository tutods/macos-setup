{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mkalias
    duf
    fd
    fnm
    doppler
    httpie
    jq
    qpdf
    smartmontools
    speedtest-cli
    tldr
    libwebp # cwebp / dwebp CLI tools
    yt-dlp
  ];
}
