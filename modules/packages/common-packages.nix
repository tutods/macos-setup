{ pkgs, nixpkgs, ghostty, ... }:
{

  environment.systemPackages = with pkgs; [
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default

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
    pkgs.montserrat
    pkgs.poppins
    pkgs.roboto
    pkgs.lato
  ];
}
