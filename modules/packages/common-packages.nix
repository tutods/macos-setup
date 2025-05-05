{ pkgs, nixpkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

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
