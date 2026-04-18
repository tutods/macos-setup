{
  goMain = {
    body = ''
      git checkout main
      git pull
    '';
    description = "Switch to main branch and pull changes";
  };

  goBranch = {
    body = ''
      git checkout "$argv"
      git pull
    '';
    description = "Switch to specified branch and pull changes";
  };

  stashAndPull = {
    body = ''
      git stash
      git pull
      git stash pop
    '';
    description = "Stash changes and pull latest";
  };

  commt = {
    body = ''
      git status --short
      read --local --prompt-str "Stage all changes and push? [y/N] " confirm
      if test "$confirm" = y
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