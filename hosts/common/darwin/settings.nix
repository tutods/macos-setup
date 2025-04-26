{ ... }:

{
  system.defaults = {
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
        # Show all file extensions
        AppleShowAllExtensions = true;
        # Show hidden files
        AppleShowAllFiles = true;
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

  # system.activationScripts.postUserActivation.text = ''
  #   defaults -currentHost write com.apple.screensaver idleTime -int 60
  # '';
  # Following line should allow us to avoid a logout/login cycle
  # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
}