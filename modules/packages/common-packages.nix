{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    yt-dlp
    gh
    mkalias
    fnm
    duf
    fd
    doppler
    speedtest-cli

    # Development
    claude-code
    jq
    tldr
    httpie

    # DevOps
    terraform

    # JetBrains development tools
    jetbrains.webstorm
    jetbrains.datagrip

    # Image optimization tools
    imagemagick
    jpegoptim
    optipng
    ffmpeg
  ];

  fonts.packages = with pkgs; [
    pkgs.jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    pkgs.montserrat
    pkgs.poppins
    pkgs.roboto
    pkgs.lato
  ];
}
