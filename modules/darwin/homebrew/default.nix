{lib, ...}: let
  developmentCasks = import ./casks/development.nix;
  browserCasks = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks = import ./casks/utils.nix;
  masApps = import ./mas.nix;
in {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;

    casks = developmentCasks ++ browserCasks ++ communicationCasks ++ utilsCasks;
  };

  system.activationScripts.installSharedMasApps.text = let
    installLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
      if ! "$mas" list 2>/dev/null | grep -q "^${toString id} "; then
        echo "  ↣ Installing ${name}"
        "$mas" install ${toString id} 2>/dev/null \
          && echo "  ✓ ${name}" \
          || echo "  ✗ ${name} failed — install manually from App Store"
      else
        echo "  ✓ ${name} already installed"
      fi
    '') masApps);
  in ''
    mas=/opt/homebrew/bin/mas
    if [ -x "$mas" ]; then
      echo "↣ App Store apps (shared)"
    ${installLines}
    fi
  '';
}
