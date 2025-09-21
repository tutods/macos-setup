# build config with --rebuild flag to force rebuild
nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.$1.system" --rebuild

# apply the config
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake ".#$1"