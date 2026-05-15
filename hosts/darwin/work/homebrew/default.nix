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
      "gcloud-cli"
      "slack"
      "warp"
      "openvpn-connect"
      "viscosity"
    ];
  };
}
