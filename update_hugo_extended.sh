#!/bin/bash
#export HUGOVER=`curl --silent "https://api.github.com/repos/gohugoio/hugo/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'`
export HUGOVER=0.90.1
export ARCH=macos-ARM64
wget https://github.com/gohugoio/hugo/releases/download/v${HUGOVER}/hugo_extended_${HUGOVER}_${ARCH}.tar.gz
tar -xvf hugo_extended_${HUGOVER}_${ARCH}.tar.gz hugo
rm hugo_extended_${HUGOVER}_${ARCH}.tar.gz
mv hugo ~/.local/bin/hugo
hugo version
