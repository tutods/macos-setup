# Shared host configuration factory.
# Each host passes its unique values; fish setup, home-manager wiring,
# and nix-homebrew flags are identical across all hosts.
#
# Usage in a host default.nix:
#   { pkgs, mkHost, ... }:
#   {
#     imports = [
#       ./dock.nix
#       ./homebrew
#       (mkHost {
#         username   = "tutods";
#         hostname   = "tutods-macbook";
#         brewUser   = "tutods";
#         homeConfig = import ../../../home/tutods/default.nix;
#       })
#     ];
#   }
{
  username,
  hostname,
  brewUser,
  homeConfig,
  masApps ? {},
}: {pkgs, lib, ...}: {
  networking.hostName = hostname;
  system.primaryUser = username;

  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  users.users.${username} = {
    ignoreShellProgramCheck = true;
  };

  system.activationScripts.extraActivation.text =
    # Fix fish code signing and set as default shell
    ''
    fish_bin="/etc/profiles/per-user/${username}/bin/fish"
    if [ -x "$fish_bin" ]; then
      if ! codesign -v "$fish_bin" 2>/dev/null; then
        echo "Re-signing fish binary (invalid code signature detected)"
        codesign --force --sign - "$fish_bin" 2>/dev/null || true
      fi
    fi

    hm_fish="/etc/profiles/per-user/${username}/bin/fish"
    sys_fish="/run/current-system/sw/bin/fish"

    if [ -x "$hm_fish" ] && ! grep -qx "$hm_fish" /etc/shells 2>/dev/null; then
      echo "Adding $hm_fish to /etc/shells"
      echo "$hm_fish" >> /etc/shells
    fi

    target_shell="$sys_fish"
    if [ -x "$hm_fish" ]; then
      target_shell="$hm_fish"
    fi

    current=$(dscl . -read /Users/${username} UserShell 2>/dev/null | awk '{print $2}')
    if [ "$current" != "$target_shell" ]; then
      echo "Setting default shell for ${username} from ${current:-default} to $target_shell"
      dscl . -create /Users/${username} UserShell "$target_shell"
    else
      echo "Default shell for ${username} is already set to $target_shell"
    fi
  ''
    # Install App Store apps via mas
    + lib.optionalString (masApps != {}) (let
      installLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
        if ! "$mas" list 2>/dev/null | grep -q "^${toString id} "; then
          echo "  ↣ Installing ${name}"
          "$mas" install ${toString id} \
            && echo "  ✓ ${name}" \
            || echo "  ✗ ${name} failed — install manually from App Store"
        else
          echo "  ✓ ${name} already installed"
        fi
      '') masApps);
    in ''
      mas=/opt/homebrew/bin/mas
      if [ -x "$mas" ]; then
        echo "↣ App Store apps"
        sudo --preserve-env=PATH --user=${username} --set-home env PATH="/opt/homebrew/bin:$PATH" bash -c '${installLines}'
      fi
    '');

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit pkgs;};
    backupFileExtension = "backup";
    users.${username} = homeConfig;
  };

  # Homebrew is owned by brewUser (may differ from the normal user on work machines)
  nix-homebrew = {
    enable = true;
    user = brewUser;
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = true;
  };
}