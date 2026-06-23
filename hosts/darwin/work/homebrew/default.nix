{...}: {
  homebrew = {
    taps = [
      "atlassian/homebrew-acli"
    ];
    brews = [
      "acli"
      "podman"
    ];
    casks = [
      "firefox"
      "gcloud-cli"
      "slack"
      "warp"
      "openvpn-connect"
    ];
  };
}
