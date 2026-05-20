{
  goMain = {
    body = ''
      git checkout main; or return 1
      git pull; or return 1
    '';
    description = "Switch to main branch and pull changes";
  };

  goBranch = {
    body = ''
      git checkout "$argv"; or return 1
      git pull; or return 1
    '';
    description = "Switch to specified branch and pull changes";
  };

  stashAndPull = {
    body = ''
      git stash; or return 1
      git pull; or return 1
      git stash pop; or begin
        echo "Stash pop had conflicts — resolve manually, then: git stash drop"
        return 1
      end
    '';
    description = "Stash changes and pull latest";
  };

  commt = {
    body = ''
      git status --short
      read --local --prompt-str "Stage all changes and push? [y/N] " confirm
      if string match -qi 'y' -- "$confirm"
        git add -A
        git commit -m "$argv"
        git push
      end
    '';
    description = "Preview, stage all changes, commit with message and push";
  };

  repo = {
    body = ''
      set url (git remote get-url origin 2>/dev/null)
      if test -z "$url"
        echo "Not a git repository or no remote set"
        return 1
      end
      set url (string replace -r '^git@([^:]+):' 'https://$1/' $url)
      set url (string replace -r '\.git$' "" $url)
      open $url
    '';
    description = "Open current git repo in browser";
  };

  killport = {
    body = ''
      if test (count $argv) -ne 1
        echo "Usage: killport <port>"
        return 1
      end
      set pids (lsof -ti tcp:$argv[1])
      if test -z "$pids"
        echo "Nothing running on port $argv[1]"
        return 0
      end
      echo $pids | xargs kill -9
      echo "Killed process(es) on port $argv[1]"
    '';
    description = "Kill process running on given port";
  };

  mkcd = {
    body = ''
      mkdir -p $argv[1] && cd $argv[1]
    '';
    description = "Create directory and cd into it";
  };

  review_commt = {
    body = ''
      if test (count $argv) -lt 1
        echo "Usage: review-commt \"commit message\""
        return 1
      end
      echo "--- UNSTAGED CHANGES ---"
      git diff | delta
      echo "--- STAGED CHANGES ---"
      git diff --cached | delta
      echo ""
      read --local --prompt-str "Everything looks correct? Stage and commit as '$argv'? [y/N] " confirm
      if string match -qi 'y' -- "$confirm"
        git add -A
        git commit -m "$argv"
        git push
      end
    '';
    description = "Visual review, then stage all changes, commit and push";
  };

  node_clean = {
    body = ''
      echo "Cleaning node_modules in ~/Developer..."
      set targets (fd -H -I -t d "^node_modules\$" ~/Developer)
      if test (count $targets) -eq 0
        echo "Nothing to clean."
        return 0
      end
      printf "%s\n" $targets
      read --local --prompt-str "Delete (count $targets) dirs? [y/N] " confirm
      if string match -qi 'y' -- "$confirm"
        fd -H -I -t d "^node_modules\$" ~/Developer -x rm -rf
        echo "Done."
      end
    '';
    description = "Recursively remove node_modules in ~/Developer (with confirmation)";
  };

  nix_vacuum = {
    body = ''
      echo "Running Nix garbage collection..."
      nix-collect-garbage -d
      echo "Optimising Nix store..."
      nix-store --optimise
      echo "Cleaning Homebrew..."
      brew cleanup
      echo "Vacuum complete."
    '';
    description = "Deep clean Nix and Homebrew environment";
  };

  fzf_jump = {
    body = ''
      set dest (fd -d 2 -t d . ~/Developer | fzf --prompt="Jump to project > ")
      if test -n "$dest"
        cd $dest
      end
    '';
    description = "Fuzzy jump to a project directory in ~/Developer";
  };

  doppler_safe = {
    body = ''
      if not git rev-parse --git-dir > /dev/null 2>&1
        echo "⚠️  Not a git repository. Guarding against secret injection into random folders."
        return 1
      end
      doppler run -- $argv
    '';
    description = "Inject secrets only if current folder is a git repo";
  };

  ytd = {
    body = ''
      yt-dlp -f bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best -o '%(upload_date)s - %(channel)s - %(id)s - %(title)s.%(ext)s' \
      --sponsorblock-mark "all" \
      --geo-bypass \
      --sub-langs 'all' \
      --embed-subs \
      --embed-metadata \
      --convert-subs 'srt' \
      $argv
    '';
    description = "Download YouTube videos with optimal settings";
  };
}
