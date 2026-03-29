{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mkalias
    duf
    fd
    fnm
    gh
    doppler
    httpie
    jq
    speedtest-cli
    tldr
    yt-dlp
  ];
}
