function goMain
    git checkout main
    git pull
end

function goMaster
    git checkout master
    git pull
end

function goBranch
    git checkout "$argv"
    git pull
end

function commt
    git add .
    git commit -m "$argv"
    git push
end