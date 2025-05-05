1. First install nix
    - `sh <(curl -L https://nixos.org/nix/install)`
2. Check if is working:
    - `nix-shell -p neofetch --run neofetch`
3. Install nix-darwin
    - `mkdir ~/nix` - to store configs
    - `nix flake init -t nix-darwin --extra-experimental-features "nix-command flakes"`
    - `sed -i '' "s/simple/$(scutil --get LocalHostName)/" ~/nix/flake.nix`
        - Or change manually the name
    - `nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/nix`
        - If change the name manually, need to add it on the end, like `#mac`
4. Check if nix-darwin is working:
    - `which darwin-rebuild`
5. Add the packages on the `flake.nix` and rebuild the config:
    - Add on `environment.systemPackages` array, for example `pkgs.alacritty`;
    - Example with fonts:
        ```
            fonts.packages = with pkgs; [
                nerd-fonts.jetbrains-mono
            ];
        ```
    - `darwin-rebuild switch --flake ~/nix`
        - If change the name manually, need to add it on the end, like `#mac`
6. Fix spotlight index
    - On configuration add `config`
        - `configuration = { pkgs, config, ... }`
    - Add on `environment.systemPackages` the `pkgs.mkalias`
    - Add the code below
    ```
        system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
        };
        in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';
      ```
7. Allow non-open-source software
    - `nixpkgs.config.allowUnfree = true;`
8. Add homebrew,
    - on `inputs = {}` add the code below:
    ```
        # Homebrew package manager
        nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

        # Optional: Declarative tap management
        homebrew-core = {
        url = "github:homebrew/homebrew-core";
        flake = false;
        };
        homebrew-cask = {
        url = "github:homebrew/homebrew-cask";
        flake = false;
        };
    ```
    - on `ouputs` add the `nix-homebrew` at the end
    - Update the `darwinConfigurations` adding on `modules` the entries:
        - `nix-homebrew.darwinModules.nix-homebrew`
        - ```
            {
                nix-homebrew = {
                    enable = true;
                    # Apple silicon only
                    enableRosetta = true;
                    # User owning the homebrew prefix
                    user = "tutods";

                    # Optional: if already have brew installed
                    autoMigrate = true;
                };
            }
        ```
9. Enable homebrew on nix, adding the following command after the fonts.packages:
    ```
        homebrew =  {
            enable = true;
            brews = [];
            casks = [];
            # Needs to be logged in on App Store before
            masApps = [];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
        };
    ```

10. Configure macos settings
    ```
        # Change macOS Settings
        system.defaults = {
            dock.autohide = true;
        };
    ```

Upgrade packages:
- `nix flake update`;
- `darwin-rebuild switch --flake ~/nix`;


# Links
https://mynixos.com
https://search.nixos.org/


- `nix --extra-experimental-features "nix-command flakes" run nix-darwin`
- `nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch`

---
install nix
```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
mkdir ~/.config/nix
cd ~/.config/nix
nix flake init -t nix-darwin
nix run nix-darwin -- switch --flake .
```

https://marceltc.com/nixing-macos-with-nix-darwin/

---
```
nix-channel --add https://github.com/nix-darwin/nix-darwin/archive/master.tar.gz darwin
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
```

https://www.dantuck.com/article/nix/setup/