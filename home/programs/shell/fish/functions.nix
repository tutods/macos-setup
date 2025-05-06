{
  goMain = {
    body = '' 
      git checkout main
      git pull
    '';  
    description = "Switch to main branch and pull changes";
  };

  goMaster = {
    body = ''
      git checkout master
      git pull
    '';
    description = "Switch to master branch and pull changes";
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
      git add .
      git commit -m "$argv"
      git push
    '';
    description = "Add all changes, commit with message and push";
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