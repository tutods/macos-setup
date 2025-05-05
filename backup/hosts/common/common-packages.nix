{ inputs, pkgs, ... }:
let
  inherit (inputs) nixpkgs;
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    jetbrains.idea-ultimate
    jetbrains.datagrip
    #jetbrains.webstorm
    gh
    bat
    fnm
    oh-my-posh
    mkalias
    duf
    fd
    doppler
    speedtest-cli
    yt-dlp

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