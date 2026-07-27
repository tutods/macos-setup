{...}: {
  homebrew = {
    taps = [
      "atlassian/homebrew-acli"
    ];
    brews = [
      "acli"
      "podman"
      "docker-compose"
    ];
    casks = [
      "firefox"
      "gcloud-cli"
      "slack"
      "openvpn-connect"
      "podman-desktop"
    ];
  };
}
