{...}: {
  homebrew = {
    taps = [
      "atlassian/homebrew-acli"
    ];
    brews = [
      "acli"
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
