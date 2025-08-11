{ pkgs, nixpkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    yt-dlp
    gh
    mkalias
    bat
    fnm
    oh-my-posh
    duf
    fd
    doppler
    speedtest-cli

    # Development
    vscode

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
  ]; 
}
