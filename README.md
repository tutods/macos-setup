1. 
```
nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.macbook.system"
```

2.
```
./result/sw/bin/darwin-rebuild switch --flake ".#macbook"
```
> OR
```
nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#macbook"
```
