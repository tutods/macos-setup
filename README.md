# macOS Setup <small>(via NixOs)</small>

This repo contains my **NixOS** configuration to setup my **macOS** machines using **NixOs** with **Nix Darwin**, **Nix Homebrew** and **Home Manager**.

This configuration is based on **[@ironicbadger](https://github.com/ironicbadger/nix-config)** configuration that is explain on [this video](https://www.youtube.com/watch?v=qUmZtC6ts0M).

Thanks [@ironicbadger](https://github.com/ironicbadger) 🙏!

## ➕ What is included?

Running this configuration, you will have:
- My shell setup (for now only with **ZSH**), with plugins, alias, etc.;
- **Homebrew** and casks/formulaes;
- **FNM** for **Node.js** version manager;
- Change most of my **macOS** settings, like:
  - Setup my dock;
  - Change networking settings to include **Google DNS**;
  - Use touch id for `sudo` commands on terminal;
  - Set timezone;
  - ...



## ▶️ How to run

1. Install **NixOS**: `sh <(curl -L https://nixos.org/nix/install)`;
  * Check if **NixOS** is working (in a new terminal) running `nix-shell -p neofetch --run neofetch`.
2. Build the configuration using: `nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.<host>.system"`;
     * Don't forget to replace `<host>` with one of the available hosts:
       - `macbook` for my person machine configuration;
       - `mindera` for my working machine - ⚠️ **IN PROGRESS**;
3. Run one of the commands above to apply the configuration:
     * `./result/sw/bin/darwin-rebuild switch --flake ".#<host>"`
     * `nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#<host>"`
     - Don't forget to replace `<host>` with one of the available hosts (details above).

To turn the second an the third step easier, I added a shell file (`nix.sh`) where is only necessary to run `sh nix.sh <host>` after install **NixOS**.

### Notes:

I didn't find a way of install a few **VSCode extensions** and configure **Hyper** terminal. So for that, run `sh post-nix.sh` to copy the `.hyper.js` configuration and install the missing **VSCode extensions**.

## 📃 Roadmap

- [ ] Prepare my configuration to work with **Linux** machines;
- [ ] Finish my working machine configuration;
- [ ] Cleanup configurations and reorganize a few parts;
- [ ] Add the possibility of choose which shell I want to use:
  - **Fish**;
  - **ZSH**.