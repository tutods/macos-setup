{
  goMain = '' 
    function goMain -d "Switch to main branch"
      git checkout main
      git pull
    end      
  '';  

  goMaster = ''
    function goMaster -d "Switch to master branch"
      git checkout master
      git pull
    end
  '';

  goBranch = ''
    function goBranch -d "Switch to a specific branch"
      git checkout "$argv"
      git pull
    end
  '';

  commt = ''
    function commt -d "Run a full commit, stagin files, do the commit message and push"
      git add .
      git commit -m "$argv"
      git push
    end
  '';

  ytd = '' 
    function ytd
      yt-dlp -f bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best -o '%(upload_date)s - %(channel)s - %(id)s - %(title)s.%(ext)s' \
      --sponsorblock-mark "all" \
      --geo-bypass \
      --sub-langs 'all' \
      --embed-subs \
      --embed-metadata \
      --convert-subs 'srt' \
      $argv
    end
  '';
}