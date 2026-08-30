# Single source for the host list and host → deploy-user map: flake.nix and nix.sh both derive from this.
{
  macbook = {
    user = "tutods";
    hostPath = ./hosts/darwin/macbook;
  };
  work = {
    user = "daniel.a.sousa";
    hostPath = ./hosts/darwin/work;
  };
}
