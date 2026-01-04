{ pkgs, ghostty, ... }:
{

  environment.systemPackages = [
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default

    pkgs.yt-dlp
    pkgs.gh
    pkgs.mkalias
    pkgs.bat
    pkgs.fnm
    pkgs.oh-my-posh
    pkgs.duf
    pkgs.fd
    pkgs.doppler
    pkgs.speedtest-cli

    # Development
    pkgs.vscode

    # DevOps
    pkgs.terraform

    # JetBrains development tools
    pkgs.jetbrains.webstorm
    pkgs.jetbrains.datagrip

    # Image optimization tools
    pkgs.imagemagick
    pkgs.jpegoptim
    pkgs.optipng
    pkgs.ffmpeg
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
