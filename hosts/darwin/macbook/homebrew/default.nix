{lib, ...}: let
  developmentCasks = import ./casks/development.nix;
  browserCasks = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks = import ./casks/utils.nix;
  fontCasks = import ./casks/fonts.nix;
  macbookMasApps = import ./mas.nix;
in {
  homebrew = {
    casks = developmentCasks ++ browserCasks ++ communicationCasks ++ utilsCasks ++ fontCasks;
  };

  system.activationScripts.extraActivation.text = lib.mkAfter (let
    installLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: id: ''
      if ! "$mas" list 2>/dev/null | grep -q "^${toString id} "; then
        echo "  ↣ Installing ${name}"
        "$mas" install ${toString id} \
          && echo "  ✓ ${name}" \
          || echo "  ✗ ${name} failed — install manually from App Store"
      else
        echo "  ✓ ${name} already installed"
      fi
    '') macbookMasApps);
  in ''
    mas=/opt/homebrew/bin/mas
    if [ -x "$mas" ]; then
      echo "↣ App Store apps (macbook)"
    ${installLines}
    else
      echo "↣ mas not found at $mas — skipping App Store installs"
    fi
  '');
}
