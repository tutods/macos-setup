{...}: {
  system = {
    defaults = {
      dock = {
        autohide = false;
        # Only takes effect when autohide is enabled; prepared for future toggle
        autohide-delay = 0.0;
        show-recents = false;
        magnification = true;
        minimize-to-application = true;
        tilesize = 32;
        largesize = 96;
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };

      finder = {
        FXPreferredViewStyle = "clmv";
        _FXSortFoldersFirst = true;
        FXRemoveOldTrashItems = true;
        NewWindowTarget = "Computer";
        ShowPathbar = true;
        ShowStatusBar = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        AppleShowAllFiles = true;
      };

      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        Sound = true;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowDate = 1;
      };

      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";
        AppleWindowTabbingMode = "always";
        KeyRepeat = 2;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        "com.apple.mouse.tapBehavior" = 1;

        NSAutomaticWindowAnimationsEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      screencapture = {
        type = "jpg";
        target = "clipboard";
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 30;
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = true;
      };

      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.finder" = {
          FXPreferredSortOrder = "name";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          ScheduleFrequency = 1;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
        };
      };
    };

    activationScripts.postActivation.text = ''
      ########################
      # SSD-specific tweaks
      ########################
      # Disable hibernation (speeds up entering sleep mode)
      sudo pmset -a hibernatemode 0
      ########################
      # Trackpad, mouse, keyboard, Bluetooth accessories, and input
      ########################
      # Increase sound quality for Bluetooth headphones/headsets
      defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
      # Follow the keyboard focus while zoomed in
      defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true
      ########################
      # Screen
      ########################
      # Disable shadow in screenshots
      defaults write com.apple.screencapture disable-shadow -bool true
      ########################
      # Finder
      ########################
      # Set sorting and sorting direction
      defaults write com.apple.finder sortColumn -string "name"
      defaults write com.apple.finder sortDirection -string "ascending"
      # Automatically open a new Finder window when a volume is mounted
      defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
      defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
      # Enable AirDrop over Ethernet and on unsupported Macs running Lion
      defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
    '';
  };
}
