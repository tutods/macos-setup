{ ... }:

{
  system = {
    defaults = {
      dock = {
        autohide = false;
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
        _FXSortFoldersFirst= true;
        FXRemoveOldTrashItems = true;
        NewWindowTarget = "Computer";
        ShowPathbar = true;
        ShowStatusBar = true;
        # When performing a search, search the current folder by default
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
      };
    
      loginwindow = {
        GuestEnabled = false;
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

        # TODO: test 
        # NSAutomaticCapitalizationEnabled = false;
        # NSAutomaticDashSubstitutionEnabled = false;
        # NSAutomaticPeriodSubstitutionEnabled = false;
        # NSAutomaticQuoteSubstitutionEnabled = false;
        # NSAutomaticSpellingCorrectionEnabled = false;
        # NSNavPanelExpandedStateForSaveMode = true;
        # NSNavPanelExpandedStateForSaveMode2 = true;
      };

      screencapture = {
        type = "jpg";
        target = "clipboard";
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 60;
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = true;
      };

      # TODO: check this config.
      CustomUserPreferences = {
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.finder" = {
          # Sort by name by default
          FXPreferredSortOrder = "name";
        };
        "com.apple.Safari" = {
          # Privacy: don't send search queries to Apple
          UniversalSearchEnabled = false;
          SuppressSearchSuggestions = true;

          # Don't open downloads (like `zip` files)
          AutoOpenSafeDownloads = false;

          # Enable developer tools
          WebKitDeveloperExtrasEnabledPreferenceKey = true;
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
      };
    };

    activationScripts.postActivation.text = ''
      # Restart automatically if the computer freezes
      sudo systemsetup -setrestartfreeze on
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
      # Require password immediately after sleep or screen saver begins
      defaults write com.apple.screensaver askForPassword -int 1
      defaults write com.apple.screensaver askForPasswordDelay -int 0
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