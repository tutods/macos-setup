{
  # Personal-specific shell configuration
  programs.fish.shellAliases = {
    docker = "podman";
  };

  xdg.configFile."containers/containers.conf".text = ''
    [engine]
    compose_warning_logs = false
  '';
}
