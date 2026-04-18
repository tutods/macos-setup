{...}:
# Public DNS for personal machine.
# Not applied to work machine — corporate DNS must resolve internal domains.
{
  networking.dns = [
    "1.1.1.1"
    "8.8.8.8"
    "8.8.4.4"
  ];
}
