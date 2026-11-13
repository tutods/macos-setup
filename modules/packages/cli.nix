{
  pkgs,
  pkgsUnstable,
  ...
}: {
  environment.systemPackages =
    (with pkgs; [
      mkalias
      duf
      fnm
      httpie
      jq
      qpdf
      ripgrep
      smartmontools
      speedtest-cli
      tldr
      libwebp # cwebp / dwebp CLI tools
      yq
      yt-dlp
    ])
    ++ [
      # security fixes land upstream faster than stable picks them up
      pkgsUnstable.ast-grep
      pkgsUnstable.fd
    ];
}
