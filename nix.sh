nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.$1.system"
nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$1"