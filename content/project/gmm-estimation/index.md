---
title: GMM/SMM/GIRF-Matching Estimation in Dynare
summary: In this project we develop a GMM/SMM/GIRF-matching toolbox for Dynare.
tags:
- Dynare
- Estimation
- GMM
- SMM
- IRF
#date: "2020-07-01T00:00:00Z"

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

# Slides (optional).
#   Associate this project with Markdown slides.
#   Simply enter your slide deck's filename without extension.
#   E.g. `slides = "example-slides"` references `content/slides/example-slides.md`.
#   Otherwise, set `slides = ""`.
#slides: example
---
In this project (joint with [Johannes Pfeifer](https://sites.google.com/site/pfeiferecon)) we develop a toolbox that enables a Method-Of-Moments estimation of dynamic and stochastic models. The code greatly improves and enhances my GMM Estimation Toolbox which I used in my *2018 Econometrics & Statistics* paper and which was based on [Martin M. Andreasen's work](https://sites.google.com/site/mandreasendk/). It is available since Dynare 4.7.

Features I am currently working on:

- [x] Add interface
- [x] GMM estimation up to third-order with pruning
- [x] SMM estimation up to any order with or without pruning
- [ ] IRF and GIRF Matching
- [x] Analytical derivatives for optimization and standard errors
- [ ] Support for measurement errors
- [ ] Speed and memory improvements
- [x] Documentation and examples