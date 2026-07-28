{...}: {
  home.file.".local/share/claude-sandbox/Containerfile".source = ./Containerfile;
  # Single source of truth — synced from the canonical common manifest.
  home.file.".local/share/claude-sandbox/skills-manifest.txt".source = ../../../../../../../skills/manifest.txt;

  programs.fish.functions.claude-sandbox = {
    description = "Run Claude Code in an isolated podman container; current dir mounted at /workspace, args pass through to claude. Set GH_TOKEN (env GH_TOKEN=... claude-sandbox) to authenticate to GitHub.";
    body = ''
      set -l image localhost/claude-sandbox:latest
      set -l ctx ~/.local/share/claude-sandbox

      if not test -f "$ctx/Containerfile"
        echo "Containerfile missing at $ctx — re-run: ./nix.sh work"
        return 1
      end

      if not podman info >/dev/null 2>&1
        echo "Podman machine not running. Start with: podman machine start"
        return 1
      end

      if not podman image exists $image 2>/dev/null
        echo "Building claude-sandbox image (first run, ~5-10 min — installs Claude Code + 14 skill sources)..."
        podman build -q -t $image "$ctx" >/dev/null
        or return 1
      end

      if not string match -q "$HOME*" "$PWD"
        echo 'Warning: $PWD is outside $HOME.'
        echo 'Podman on macOS only mounts paths under $HOME by default.'
        read --local --prompt-str "Continue anyway? [y/N] " confirm
        string match -qi 'y' -- "$confirm"; or return 1
      end

      podman run --rm -it \
        -v "$PWD":/workspace \
        -v claude-sandbox-config:/home/claude/.claude \
        -e GH_TOKEN \
        -w /workspace \
        $image $argv
    '';
  };
}
