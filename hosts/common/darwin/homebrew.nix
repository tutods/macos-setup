{...}:

{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;

    brews = [
      "mas"
      "webp"
    ];
    casks = [
      # Web
      "arc"
      "firefox"
      "zen-browser"
      "google-chrome"
      "brave-browser"
      "qbittorrent"
      "discord"
      "telegram"
      "whatsapp"
      "slack"

      # Developer tools
      "cursor"
      "windsurf"
      "trae"
      "visual-studio-code"
      "hyper"
      "warp"
      "orbstack"
      "jetbrains-toolbox"
      "bruno"
      "httpie"
      "insomnia"

      # Design
      "figma"

      # Tools
      "stats"
      "onyx"
      "pearcleaner"
      
      # Remote control
      "teamviewer"
      "anydesk"

      # Notes
      "notion"
      # "obsidian"

      # Other
      "bitwarden"
      "raycast"
      "airbuddy"
      "iina"
      "jordanbaird-ice"
      "logi-options+"
      # "vlc"
      #"balenaetcher"
      
      # VPNs
      # "tailscale"
      # ----
      "marta"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Keynote" = 409183694;
      "Magnet" = 441258766;
      "1Blocker" = 1365531024;
      "Affinity Designer" = 824171161;
      "Affinity Photo" = 824183456;
      "Baking Soda" = 1601151613;
      "Vinegar" = 1591303229;
      "PhotoBulk" = 537211143;
      "PasteNow" = 1552536109;
      "Xnip" = 1221250572;
      "Elmedia Video Player" = 1044549675;
      "SnippetsLab" = 1006087419;
      "Tailscale" = 1475387142;
    };
  };
}