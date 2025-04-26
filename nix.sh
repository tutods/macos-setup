# build config
nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.$1.system"
# apply the config
nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#$1"