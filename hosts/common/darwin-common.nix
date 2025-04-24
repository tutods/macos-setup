{ inputs, outputs, config, lib, hostname, system, username, pkgs, ... }:
let
  inherit (inputs) nixpkgs;
in
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
    # channel.enable = false;
  };
  # services.nix-daemon.enable = true;
  system.stateVersion = 6;

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = lib.mkDefault "${system}";
  };

  # pins to stable as unstable updates very often
  # nix.registry = {
  #   n.to = {
  #     type = "path";
  #     path = inputs.nixpkgs;
  #   };
  #   u.to = {
  #     type = "path";
  #     path = inputs.nixpkgs-unstable;
  #   };
  # };

  # programs.nix-index.enable = true;

  # programs.zsh = {
  #   enable = true;
  #   enableCompletion = true;
  #   promptInit = builtins.readFile ./../../data/mac-dot-zshrc;
  # };

  homebrew = import ./darwin/homebrew.nix // { enable = true; };
  # homebrew = {
  #   enable = true;
  #   onActivation = {
  #     cleanup = "zap";
  #     autoUpdate = true;
  #     upgrade = true;
  #   };
  #   global.autoUpdate = true;

  #   brews = [
  #     "mas"
  #     #"borders"
  #   ];
  #   taps = [
  #     #"FelixKratz/formulae" #sketchybar
  #   ];
  #   casks = [
  #     "firefox"
  #     "google-chrome"
  #     "qbittorrent"
  #     "orbstack"
  #     "bitwarden"
  #     "iina"
  #     "visual-studio-code"
  #     "hyper"
  #     "cursor"
  #     "jetbrains-toolbox"
  #     "trae"
  #     "hyper"
  #     "windsurf"
  #     "notion"
  #     "jordanbaird-ice"

  #     # ----
  #     # "screenflow"
  #     # "cleanshot"
  #     # "adobe-creative-cloud"
  #     # #"nikitabobko/tap/aerospace"
  #     # "alacritty"
  #     # "alcove"
  #     # "audacity"
  #     # #"balenaetcher"
  #     # "bambu-studio"
  #     # "bentobox"
  #     # #"clop"
  #     # "discord"
  #     # "displaylink"
  #     # #"docker"
  #     # "element"
  #     # "elgato-camera-hub"
  #     # "elgato-control-center"
  #     # "elgato-stream-deck"
  #     # "firefox"
  #     # "flameshot"
  #     # "font-fira-code"
  #     # "font-fira-code-nerd-font"
  #     # "font-fira-mono-for-powerline"
  #     # "font-hack-nerd-font"
  #     # "font-jetbrains-mono-nerd-font"
  #     # "font-meslo-lg-nerd-font"
  #     # "ghostty"
  #     # "google-chrome"
  #     # "iina"
  #     # "istat-menus"
  #     # "iterm2"
  #     # "jordanbaird-ice"
  #     # "lm-studio"
  #     # "logitech-options"
  #     # "macwhisper"
  #     # "marta"
  #     # "mqtt-explorer"
  #     # "music-decoy" # github/FuzzyIdeas/MusicDecoy
  #     # "nextcloud"
  #     # "notion"
  #     # "obs"
  #     # "obsidian"
  #     # "ollama"
  #     # "omnidisksweeper"
  #     # "orbstack"
  #     # "openscad"
  #     # "openttd"
  #     # "plexamp"
  #     # "popclip"
  #     # "prusaslicer"
  #     # "raycast"
  #     # "signal"
  #     # "shortcat"
  #     # "slack"
  #     # "spotify"
  #     # "steam"
  #     # "tailscale"
  #     # "warp"
  #     # #"wireshark"
  #     # "viscosity"
  #     # "visual-studio-code"
  #     # "vlc"
  #     # # "lm-studio"

  #     # # # rogue amoeba
  #     # "audio-hijack"
  #     # "farrago"
  #     # "loopback"
  #     # "soundsource"
  #   ];
  #   masApps = {
  #     "Tailscale" = 1475387142;
  #     "Amphetamine" = 937984704;
  #     "Numbers" = 409203825;
  #     "Pages" = 409201541;
  #     "Keynote" = 409183694;
  #     "Magnet" = 441258766;
  #     "1Blocker" = 1365531024;
  #     "Affinity Designer" = 824171161;
  #     "Affinity Photo" = 824183456;
  #     "Baking Soda" = 1601151613;
  #     "PhotoBulk" = 537211143;
  #     "PasteNow" = 1552536109;
  #     "Xnip" = 1221250572;
  #     "Elmedia Video Player" = 1044549675;
  #     "SnippetsLab" = 1006087419;
  #   };
  # };

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = false;

  # Add ability to used TouchID for sudo authentication
  security.pam = {
    services = {
      sudo_local = {
        touchIdAuth = true;
      };
    };
  };

  # macOS configuration
  system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowScrollBars = "Always";
    NSGlobalDomain.NSUseAnimatedFocusRing = false;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
    NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain.InitialKeyRepeat = 25;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    NSGlobalDomain.NSWindowShouldDragOnGesture = true;
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
    LaunchServices.LSQuarantine = false; # disables "Are you sure?" for new apps
    loginwindow.GuestEnabled = false;
    finder.FXPreferredViewStyle = "Nlsv";
  };

  system.defaults.CustomUserPreferences = {
      "com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        # When performing a search, search the current folder by default
        FXDefaultSearchScope = "SCcf";
        DisableAllAnimations = true;
        NewWindowTarget = "PfDe";
        NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        ShowStatusBar = true;
        ShowPathbar = true;
        WarnOnEmptyTrash = false;
      };
      "com.apple.desktopservices" = {
        # Avoid creating .DS_Store files on network or USB volumes
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock" = {
        autohide = false;
        launchanim = false;
        static-only = false;
        show-recents = false;
        show-process-indicators = true;
        orientation = "left";
        tilesize = 36;
        minimize-to-application = true;
        mineffect = "scale";
        enable-window-tool = false;
      };
      "com.apple.ActivityMonitor" = {
        OpenMainWindow = true;
        IconType = 5;
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };
      "com.apple.Safari" = {
        # Privacy: don’t send search queries to Apple
        UniversalSearchEnabled = false;
        SuppressSearchSuggestions = true;
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        # Check for software updates daily, not just once per week
        ScheduleFrequency = 1;
        # Download newly available updates in background
        AutomaticDownload = 1;
        # Install System data files & security updates
        CriticalUpdateInstall = 1;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      # Prevent Photos from opening automatically when devices are plugged in
      "com.apple.ImageCapture".disableHotPlug = true;
      # Turn on app auto-update
      "com.apple.commerce".AutoUpdate = true;
      "com.googlecode.iterm2".PromptOnQuit = false;
      "com.google.Chrome" = {
        AppleEnableSwipeNavigateWithScrolls = true;
        DisablePrintPreview = true;
        PMPrintingExpandedStateForPrint2 = true;
      };
  };

}
