nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update


# Populate the NIX_PATH environment variable for both zsh and bash shells.
# It's a workaround for this issue that seems to have been introduced in Nix 2.4,
# in that the installation of Nix no longer seems to populate it for you.
# https://github.com/nix-community/home-manager/issues/2564#issuecomment-994943471
echo 'export NIX_PATH=${NIX_PATH:+$NIX_PATH:}$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels\n' >> ~/.bash_profile
echo 'export NIX_PATH=${NIX_PATH:+$NIX_PATH:}$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels\n' >> ~/.zshenv 

# Install Home Manager
nix-shell '<home-manager>' -A install