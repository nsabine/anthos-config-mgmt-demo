git checkout main
git pull
git branch -d new-app
git push origin --delete new-app

git rm ../policy/namespaces/dlp/*
git rm ../policy/namespaces/dlp

git commit -m "removing dlp deployment"
git push

