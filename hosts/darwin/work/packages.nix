# System packages for work laptop.
# Add company-required tools here (e.g., corporate VPN, authentication agents).
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [];
}
