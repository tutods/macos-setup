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

    # JetBrains development tools
    jetbrains.idea-ultimate
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
