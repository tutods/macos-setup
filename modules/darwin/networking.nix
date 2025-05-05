{ ... }:

{
  networking = {
   dns = [
      "8.8.8.8"
      "8.8.4.4"
      "1.1.1.1"
    ];
    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet Adaptor"
      "Thunderbolt Ethernet"
      "Thunderbolt Bridge"
      "Tailscale"
    ];
  };
}