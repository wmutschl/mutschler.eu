---
title: GMM/SMM/IRF-Matching Estimation in Dynare
summary: In this project (joint with the Dynare Team) we plan to provide an interface for a GMM/SMM/IRF-matching toolbox in Dynare.
tags:
- Dynare
- Estimation
- GMM
- SMM
- IRF
date: 2020-07-01

# Optional external URL for project (replaces project detail page).
external_link: ""

image:
#  caption: 'Image credit: [**the moment**](https://www.flickr.com/photos/86348981@N04/7914343608) by NM3792 is licensed under CC BY-NC 2.0'
  caption: 'Image credit: [**Estimation: The Fine Art of Guessing**](https://www.amazon.com/Agile-Samurai-Software-Pragmatic-Programmers/dp/1934356581) by Jonathan Rasmusson'
  focal_point: Smart

links:
#- icon: twitter
#  icon_pack: fab
#  name: Follow
#  url: https://twitter.com/georgecushen
#url_code: ""
#url_pdf: ""
#url_slides: ""
#url_video: ""
links:
- name: RoadMap
  url: https://git.dynare.org/Dynare/dynare/-/wikis/RoadMap
- name: PullRequest
  url: https://git.dynare.org/Dynare/dynare/-/merge_requests/1750
# Slides (optional).
#   Associate this project with Markdown slides.
#   Simply enter your slide deck's filename without extension.
#   E.g. `slides = "example-slides"` references `content/slides/example-slides.md`.
#   Otherwise, set `slides = ""`.
#slides: example
---
In this project (joint with the Dynare Team) we plan to provide an interface for a GMM/SMM/IRF-matching toolbox at perturbation orders up to three (using pruning) in Dynare. The code adapts the GMM Estimation Toolbox of Martin M. Andreasen and is documented in my *Econometrics & Statistics* paper.

We have pushed a first implementation that is able to do GMM and SMM on nonlinear DSGE models to the master branch of Dynare. Now we are working on the exact interface.