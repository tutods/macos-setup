{
  lib,
  pkgs,
  ...
}: let
  model = "gpt-5.5";
  reasoningEffort = "xhigh";
in {
  home.activation.codexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        target="$HOME/.codex/config.toml"
        mkdir -p "$HOME/.codex"

        # Preserve [projects.*] sections written at runtime by codex
        projects=""
        if [ -f "$target" ]; then
          export _CODEX_TARGET="$target"
          projects=$(${pkgs.python3}/bin/python3 <<'PYEOF'
    import os
    lines = open(os.environ['_CODEX_TARGET']).readlines()
    in_proj, out = False, []
    for l in lines:
        s = l.strip()
        if s.startswith('[projects.'):
            in_proj = True
        elif s.startswith('[') and not s.startswith('[projects.') and in_proj:
            in_proj = False
        if in_proj:
            out.append(l)
    print('''.join(out), end=''')
    PYEOF
    )
        fi

        printf 'model = "%s"\nmodel_reasoning_effort = "%s"\nplan_mode_reasoning_effort = "%s"\ndisable_response_storage = true\n' \
          '${model}' '${reasoningEffort}' '${reasoningEffort}' > "$target"

        [ -n "$projects" ] && printf '\n%s\n' "$projects" >> "$target"
  '';
}
