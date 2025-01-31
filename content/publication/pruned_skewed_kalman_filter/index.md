---
title: 'Pruned skewed Kalman filter and smoother with applications to DSGE models'

# Authors
# If you created a profile for a user (e.g. the default `admin` user), write the username (folder name) here
# and it will be replaced with their full name and linked to their profile.
authors:
  - Gaygysyz Guljanov
  - Willi Mutschler
  - Mark Trede

# Author notes (optional)
#author_notes:
#  - 'Equal contribution'
#  - 'Equal contribution'

date: '2025-01-29'
doi: ''

# Schedule page publish date (NOT publication's date).
publishDate: ''

# Publication type.
# Legend: 0 = Uncategorized; 1 = Conference paper; 2 = Journal article;
# 3 = Preprint / Working Paper; 4 = Report; 5 = Book; 6 = Book section;
# 7 = Thesis; 8 = Patent
publication_types: ['3']

# Publication name and optional abbreviated publication name.
publication: CQE Working Paper 101, Dynare Working Papers 78
publication_short: ''

abstract: "The *skewed Kalman filter* (SKF) extends the classical *Gaussian Kalman filter* (KF) by accommodating asymmetric (skewed) error distributions in linear state-space models. We introduce a computationally efficient method to address the *curse of increasing skewness dimensions* inherent in the {SKF}. Building on insights into how skewness propagates through the state-space system, we derive an algorithm that discards elements in the cumulative distribution functions which do not affect asymmetry beyond a pre-specified numerical threshold; we refer to this approach as the *pruned skewed Kalman filter* (PSKF). Through extensive simulation studies on both univariate and multivariate state-space models, we demonstrate the proposed method's accuracy and efficiency. Furthermore, we are first to derive the *skewed Kalman smoother* and implement its pruned variant. We illustrate its practical relevance by estimating a linearized New Keynesian DSGE model with U.S. data under both maximum likelihood and Bayesian MCMC frameworks. The results reveal a strong preference for skewed error distributions, especially in productivity and monetary policy shocks."


# Summary. An optional shortened abstract.
summary: "The *skewed Kalman filter* (SKF) extends the classical *Gaussian Kalman filter* (KF) by accommodating asymmetric (skewed) error distributions in linear state-space models. We introduce a computationally efficient method to address the *curse of increasing skewness dimensions* inherent in the {SKF}. Building on insights into how skewness propagates through the state-space system, we derive an algorithm that discards elements in the cumulative distribution functions which do not affect asymmetry beyond a pre-specified numerical threshold; we refer to this approach as the *pruned skewed Kalman filter* (PSKF). Through extensive simulation studies on both univariate and multivariate state-space models, we demonstrate the proposed method's accuracy and efficiency. Furthermore, we are first to derive the *skewed Kalman smoother* and implement its pruned variant. We illustrate its practical relevance by estimating a linearized New Keynesian DSGE model with U.S. data under both maximum likelihood and Bayesian MCMC frameworks. The results reveal a strong preference for skewed error distributions, especially in productivity and monetary policy shocks."

tags:
  - state-space models
  - skewed Kalman filter
  - skewed Kalman smoother
  - closed skew-normal
  - dimension reduction
  - asymmetric shocks
  - yield curve
  - term structure
  - dynamic Nelson-Siegel
  - DSGE
  - monetary policy

# Display this page in the Featured widget?
featured: false

links:
  - name: Online Appendix
    url: /files/papers/GuljanovMutschlerTrede_PSKF_Online_Appendix.pdf
  - name: CQE Working Paper 101
    url: https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/cqe_wp_101_2022.pdf
  - name: Dynare Working Paper 78
    url: https://www.dynare.org/wp-repo/dynarewp078.pdf
  - name: Replication Files
    url: https://github.com/wmutschl/pruned-skewed-kalman-paper
  - name: Development Dynare Toolbox
    url: https://git.dynare.org/wmutschl/dynare/-/tree/pskf
url_pdf: ''
url_code: ''
url_dataset: ''
url_poster: ''
url_project: ''
url_slides: ''
url_source: ''
url_video: ''
url_preprint: '/files/papers/GuljanovMutschlerTrede_PSKF.pdf'

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
image:
  caption: ''
  focal_point: ''
  preview_only: false

# Associated Projects (optional).
#   Associate this publication with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `internal-project` references `content/project/internal-project/index.md`.
#   Otherwise, set `projects: []`.
projects:
  - dynare

# Slides (optional).
#   Associate this publication with Markdown slides.
#   Simply enter your slide deck's filename without extension.
#   E.g. `slides: "example"` references `content/slides/example/index.md`.
#   Otherwise, set `slides: ""`.
slides: ""
---