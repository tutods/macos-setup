{
  config,
  lib,
  pkgs,
  ...
}: let
  servers = import ../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  codexServers = {
    filesystem = servers.filesystem;
    github = servers.github;
    playwright = servers.playwright;
  };
in {
  # codex: ~/.codex/config.toml  ([mcp_servers.*] — Nix authoritative)
  home.activation.codexMcp = lib.hm.dag.entryAfter ["writeBoundary" "codexConfig"] ''
        target="$HOME/.codex/config.toml"
        [ -f "$target" ] || exit 0

        export _CODEX_TARGET="$target"
        export _CODEX_MCP='${builtins.toJSON codexServers}'

        ${pkgs.python3}/bin/python3 <<'PYEOF'
    import json, os

    target = os.environ['_CODEX_TARGET']
    servers = json.loads(os.environ['_CODEX_MCP'])

    lines = open(target).readlines()

    # Nix owns [mcp_servers.*] — strip existing blocks
    filtered, in_mcp = [], False
    for l in lines:
        s = l.strip()
        if s.startswith('[mcp_servers'):
            in_mcp = True
        elif s.startswith('[') and in_mcp:
            in_mcp = False
        if not in_mcp:
            filtered.append(l)

    # Trim trailing blank lines, then add separator
    while filtered and not filtered[-1].strip():
        filtered.pop()
    filtered.append('\n')

    for name, cfg in servers.items():
        filtered.append(f'\n[mcp_servers.{name}]\n')
        filtered.append(f'command = {json.dumps(cfg["command"])}\n')
        args = ', '.join(json.dumps(a) for a in cfg.get('args', []))
        filtered.append(f'args = [{args}]\n')

    with open(target, 'w') as f:
        f.writelines(filtered)
    PYEOF
  '';
}
