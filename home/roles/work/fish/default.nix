{...}: {
  programs.fish.shellInit = ''
    if test -d /opt/homebrew/share/google-cloud-sdk/bin
      if not contains "/opt/homebrew/share/google-cloud-sdk/bin" $fish_user_paths
        set -U fish_user_paths /opt/homebrew/share/google-cloud-sdk/bin $fish_user_paths
      end
    end
  '';
}
