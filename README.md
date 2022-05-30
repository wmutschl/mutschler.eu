I am using the [Academic Theme](https://github.com/wowchemy/starter-hugo-academic) for [Hugo](https://github.com/gohugoio/hugo) for my personal homepage located at <https://mutschler.eu> and [deploy it with rsync](https://gohugo.io/hosting-and-deployment/deployment-with-rsync/) to my server.

This repository contains all content on the homepage and two useful scripts:

* `update_hugo_extended.sh`: downloads the most recent version of Hugo Extended binary and copies it over to $HOME/.local/bin (make sure it is in your $PATH)
* `hugo_rsync.sh`: rsync command I use to deploy to my server