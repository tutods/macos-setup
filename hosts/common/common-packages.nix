{ inputs, pkgs, ... }:
let
  inherit (inputs) nixpkgs;
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    yt-dlp
    gh
    htop
    mkalias
    bat
    eza
    fnm
    fzf
    zoxide
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

# # nixpkgs-unstable.legacyPackages.${pkgs.system}.beszel
# # nixpkgs-unstable.legacyPackages.${pkgs.system}.talosctl

# ## stable
# act
# ansible
# btop
# coreutils
# diffr # Modern Unix `diff`
# difftastic # Modern Unix `diff`
# drill
# du-dust # Modern Unix `du`
# dua # Modern Unix `du`
# duf # Modern Unix `df`
# entr # Modern Unix `watch`
# esptool
# fastfetch
# fd
# ffmpeg
# figurine
# fira-code
# # fira-code-nerdfont
# # fira-mono
# gh
# git-crypt
# gnused
# go
# hugo
# iperf3
# ipmitool
# # jetbrains-mono # font
# jq
# just
# kubectl
# mc
# mosh
# # nerdfonts
# nmap
# qemu
# ripgrep
# skopeo
# smartmontools
# television
# terraform
# tree
# unzip
# watch
# wget
# wireguard-tools
# zoxide

# # requires nixpkgs.config.allowUnfree = true;
# # vscode-extensions.ms-vscode-remote.remote-ssh