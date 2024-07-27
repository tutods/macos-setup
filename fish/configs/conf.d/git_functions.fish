function goMain -d "Switch to main branch"
    git checkout main
    git pull
end

function goMaster -d "Switch to master branch"
    git checkout master
    git pull
end

function goBranch -d "Switch to a specific branch"
    git checkout "$argv"
    git pull
end

function commt -d "Run a full commit, stagin files, do the commit message and push"
    git add .
    git commit -m "$argv"
    git push
end