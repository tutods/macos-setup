{...}: let
  developmentCasks = import ./casks/development.nix;
  browserCasks = import ./casks/browsers.nix;
  communicationCasks = import ./casks/communication.nix;
  utilsCasks = import ./casks/utils.nix;
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
    masApps = import ./mas.nix;
  };

  system.activationScripts.homebrewOrigin.text = ''
    brewDir="/opt/homebrew/Library/.homebrew-is-managed-by-nix"
    if [ -d "$brewDir" ]; then
      # nix-homebrew creates a minimal .git with just a HEAD file;
      # initialise it as a proper repo so the origin remote can be set.
      if [ ! -f "$brewDir/.git/HEAD" ] || [ ! -f "$brewDir/.git/config" ]; then
        git -C "$brewDir" init >/dev/null 2>&1
      fi
      if ! git -C "$brewDir" remote get-url origin &>/dev/null; then
        echo "Setting Homebrew git origin remote"
        git -C "$brewDir" remote add origin https://github.com/Homebrew/brew
      fi
    fi
  '';
}
