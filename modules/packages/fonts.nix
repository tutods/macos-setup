# Nixpkgs fonts applied to all hosts.
# Homebrew cask fonts (font-satisfy, font-josefin-sans) are macbook-only:
# → hosts/darwin/macbook/homebrew/casks/fonts.nix
{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    montserrat
    poppins
    roboto
    lato
  ];
}
