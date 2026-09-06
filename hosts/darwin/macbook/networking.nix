{...}:
# Public DNS for personal machine.
# Deliberately macbook-only: setting knownNetworkServices with empty dns/search
# makes nix-darwin reset DNS on every deploy, which would wipe the work
# machine's corporate/VPN resolvers. Tailscale is excluded so MagicDNS
# (*.ts.net) keeps resolving.
{
  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet Adaptor"
      "Thunderbolt Ethernet"
      "Thunderbolt Bridge"
    ];

    dns = [
      "1.1.1.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
}
