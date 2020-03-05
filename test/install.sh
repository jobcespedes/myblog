#!/bin/bash -x
# https://zwbetz.com/script-to-install-latest-hugo-release-on-linux-and-mac/

pushd /tmp/

latest_hugo=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
| grep "browser_download_url.*hugo_[^extended].*_Linux-64bit\.tar\.gz" \
| cut -d ":" -f 2,3 \
| tr -d \") \

curl -L ${latest_hugo} | tar xzv

chmod +x hugo

sudo mv hugo /usr/local/bin/

popd

location="$(which hugo)"
echo "Hugo binary location: $location"

version="$(hugo version)"
echo "Hugo binary version: $version"
