#!/bin/bash
# https://cjolowicz.github.io/posts/hosting-a-hugo-blog-on-github-pages-with-travis-ci/#setting-up-the-blog-repository

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

cd public

if [ -n "$GITHUB_AUTH_SECRET" ]
then
    touch ~/.git-credentials
    chmod 0600 ~/.git-credentials
    echo $GITHUB_AUTH_SECRET > ~/.git-credentials

    git config credential.helper store
    git config user.email "jobcespedes+cibot@gmail.com"
    git config user.name "Personal CI Bot"
fi

git add -A
git commit -m "rebuilding site on `date`, commit ${TRAVIS_COMMIT} and job ${TRAVIS_JOB_NUMBER}" || true
git push --force origin HEAD:master
