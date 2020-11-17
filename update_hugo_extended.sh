#!/bin/bash
export HUGOVER=`curl --silent "https://api.github.com/repos/gohugoio/hugo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'`
wget https://github.com/gohugoio/hugo/releases/download/v${HUGOVER:1}/hugo_extended_${HUGOVER:1}_Linux-64bit.tar.gz
tar -xvf hugo_extended_${HUGOVER:1}_Linux-64bit.tar.gz hugo
rm hugo_extended_${HUGOVER:1}_Linux-64bit.tar.gz
mv hugo ~/.local/bin/hugo
hugo version
