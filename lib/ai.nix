# Shared helpers for the per-tool AI wiring tree (claude, opencode).
#
# Why this exists: claude/opencode each had their own copy of the same
# patterns — a tiny `mkMcp`-style helper, a jq-based "merge key into JSON file"
# activation script, and an append-if-non-empty concatenator. Concentrating
# those here means a new tool is one call site, not new copies.
#
# Import as: `let ai = import ../../lib/ai.nix { inherit pkgs; }; in ...`
{pkgs}: let
  jqBin = "${pkgs.jq}/bin/jq";
in {
  # Build an MCP server record. Replaces the duplicated `mkMcp` helpers that
  # lived in roles/personal/ai/default.nix and roles/work/ai/default.nix.
  mkServer = {
    cmd,
    args,
    env ? {},
  }: {
    command = cmd;
    inherit args env;
  };

  # Append `extra` to `base` only when `extra` is non-empty.
  # Replaces the appendIfNonEmpty in instructions/default.nix (the list branch
  # was dead — extraInstructions is always `lines`).
  appendIfNonEmpty = base: extra:
    if extra == ""
    then base
    else base + "\n\n" + extra;

  # Generate a bash snippet that merges a single key into a JSON config file
  # via jq, creating the file with `{"<key>": <value>}` if it does not exist.
  #
  # Used by claude/mcp.nix (key="mcpServers") and opencode/mcp.nix (key="mcp").
  mergeJsonKey = {
    file,
    key,
    value,
    extraMerge ? null,
  }: let
    mergeClause =
      if extraMerge == null
      then ''. + {${key}: $v}''
      else extraMerge;
  in ''
    target="${file}"
    nix_value='${builtins.toJSON value}'
    mkdir -p "$(dirname "$target")"
    if [ -f "$target" ]; then
      ${jqBin} --argjson v "$nix_value" '${mergeClause}' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"${key}\": $nix_value}" | ${jqBin} '.' > "$target"
    fi
  '';
}
