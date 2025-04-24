{ pkgs, unstable, ... }: {
  imports = [
    # ./zsh.nix
    # ./zellij.nix
    # ./tmux.nix
    # ./git.nix
    # ./k9s.nix
    # ./kubie.nix
    #./krew.nix
  ];

  home = {
    packages = with pkgs; [
      # neovim # customized by overlay

      # # terminal
      # # TODO: currently broken
      # #unstable.ghostty

      # # net tools
      # bind
      # nmap
      # inetutils

      # # core
      # openssl
      # wget
      # curl
      # fd
      # ripgrep # fast search

      # grc # colored log output
      # gitAndTools.delta # pretty diff tool
      # sshfs # mount folders via ssh
      # gh # github cli tool
      # glab # gitlab cli tool
      # graph-easy # draw graphs in the terminal
      # cht-sh # cheat sheet -> cht python read file
      # tealdeer # community driven man pages
      # dive # analyse docker images
      # hyperfine # benchmark tool
      # sipcalc # ip subnet calculator
      # yt-dlp # download youtube videos
      # ffmpeg # video editing and cutting
      # rclone # sync files
      # duf # disk usage
      # httpie # awesome alternative to curl
      # mongodb-tools
      # pulumi-bin # manage infrastructure as code
      # viddy # terminal watch command
      # unixtools.watch # watches commands
      # yq-go # yaml, toml parser
      # termdown # terminal countdown
      # tmate # share terminal via web
      # silicon # create code snippets as images
      # crane # container registry tool
      # ytt # yaml templating engine
      # zk # zettelkasten
      # mask # taskrunner
      # gnupg # gpg
      # gping # ping with a graph
      # ruby # scripting language
      # corepack # node wrappers
      # redis # to use the cli
      # k6 # load testing tool
      # slides # terminal presentation tool
      # presenterm # presentation tool
      # asdf-vm # managing different versions
      # comma # run nix binaries on demand
      # sshuttle # vpn over ssh
      # fblog # json log viewer
      # terraform
      # opentofu
      # putty # for kubernetes training

      # # work
      # kafkactl # kafka
      # openconnect # cli vpn client

      # # gnu binaries
      # coreutils-full # multiple tools
      # gnutar
      # gnused
      # gnugrep
      # gnumake
      # gzip
      # findutils
      # gawk

      # # kubernetes stuff
      # kubectl
      # kubelogin # oidc login azure
      # krew # kubectl plugins
      # kubie # fzf kubeconfig browser
      # kind # k8s in docker
      # velero # k8s backup tool
      # fluxcd # automation
      # kubent # check for deprecations
      # termshark # tui for wireshark
      # prometheus # prometheus linter
      # kubebuilder # generate controller
      # kubernetes-helm # deploy applications

      # # cloud
      # google-cloud-sdk
      # awscli2
      # azure-cli
      # openstackclient
      # s3cmd

      # # programming

      # ## python
      # python3
      # #poetry # python tools # TODO tests failing


      ## node
      deno # node runtime
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.pnpm
    ];

    shellAliases = {
      # builtins
      size = "du -sh";
      cp = "cp -i";
      mkdir = "mkdir -p";
      df = "df -h";
      free = "free -h";
      du = "du -sh";
      del = "rm -rf";
      lst = "ls --tree -I .git";
      lsl = "ls -l";
      lsa = "ls -a";
      null = "/dev/null";

      # overrides
      cat = "bat";
      top = "btop";
      htop = "btop";
      ping = "gping";
      ssh = "TERM=screen ssh";
      python = "python3";
      pip = "python3 -m pip";
      venv = "python3 -m venv";

      # programs
      g = "git";
      d = "docker";
      dc = "docker-compose";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "/opt/homebrew/bin"
    ];
  };

  programs = {
    # let home-manager manage itself
    home-manager.enable = true;

    # shell integrations are enabled by default
    nushell.enable = true; # zsh alternative
    zoxide.enable = true; # autojump
    jq.enable = true; # json parser
    bat.enable = true; # pretty cat
    lazygit.enable = true; # git tui
    yazi.enable = true; # file browser
    btop.enable = true; # htop alternative
    broot.enable = true; # browser big folders
    carapace.enable = true; # autocompletion

    # pretty prompt
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };

    # pretty ls
    lsd = {
      enable = true;
      enableAliases = true;
    };

    htop = {
      enable = true;
      settings = {
        tree_view = true;
        show_cpu_frequency = true;
        show_cpu_usage = true;
        show_program_path = false;
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand =
        "fd --type f --hidden --follow --exclude .git --exclude .vim --exclude .cache --exclude vendor --exclude node_modules";
      defaultOptions = [
        "--border sharp"
        "--inline-info"
      ];
    };
  };
}