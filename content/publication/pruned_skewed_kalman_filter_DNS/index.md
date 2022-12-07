---
title: 'Pruned Skewed Kalman Filter and Smoother: With Application to the Yield Curve'

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

date: '2022-12-07'
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

abstract: "The *Skewed Kalman Filter* is a powerful tool for statistical inference of asymmetrically distributed time series data.
However, the need to evaluate Gaussian cumulative distribution functions (cdf) of increasing dimensions, creates a numerical barrier
such that the filter is usually applicable for univariate models and under simplifying conditions only.
Based on the intuition of how skewness propagates through the state-space system,
a computationally efficient algorithm is proposed to *prune* the overall skewness dimension
by discarding elements in the cdfs that do not distort the symmetry up to a pre-specified numerical threshold.    
Accuracy and efficiency of this *Pruned Skewed Kalman Filter* for general multivariate state-space models are illustrated through an extensive simulation study.    
The *Skewed Kalman Smoother* and its pruned implementation are also derived.
Applicability is demonstrated by estimating a multivariate dynamic Nelson-Siegel term structure model of the US yield curve with Maximum Likelihood methods.
We find that the data clearly favors a skewed distribution for the innovations to the latent level, slope and curvature factors."


# Summary. An optional shortened abstract.
summary: "The *Skewed Kalman Filter* is a powerful tool for statistical inference of asymmetrically distributed time series data.
However, the need to evaluate Gaussian cumulative distribution functions (cdf) of increasing dimensions, creates a numerical barrier
such that the filter is usually applicable for univariate models and under simplifying conditions only.
Based on the intuition of how skewness propagates through the state-space system,
a computationally efficient algorithm is proposed to *prune* the overall skewness dimension
by discarding elements in the cdfs that do not distort the symmetry up to a pre-specified numerical threshold.    
Accuracy and efficiency of this *Pruned Skewed Kalman Filter* for general multivariate state-space models are illustrated through an extensive simulation study.    
The *Skewed Kalman Smoother* and its pruned implementation are also derived.
Applicability is demonstrated by estimating a multivariate dynamic Nelson-Siegel term structure model of the US yield curve with Maximum Likelihood methods.
We find that the data clearly favors a skewed distribution for the innovations to the latent level, slope and curvature factors."

tags:
  - state-space models
  - skewed Kalman filter
  - skewed Kalman smoother
  - closed skew-normal
  - dimension reduction
  - yield curve
  - term structure
  - dynamic Nelson-Siegel

# Display this page in the Featured widget?
featured: false

links:
  - name: Online Appendix
    url: /files/papers/GuljanovMutschlerTrede_PSKF_DNS_Online_Appendix.pdf
  - name: CQE Working Paper 101
    url: https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/cqe_wp_101_2022.pdf
  - name: Dynare Working Paper 78
    url: https://www.dynare.org/wp-repo/dynarewp078.pdf
url_pdf: /files/papers/GuljanovMutschlerTrede_PSKF_DNS.pdf
url_code: https://github.com/wmutschl/pruned-skewed-kalman-dns-paper
url_dataset: ''
url_poster: ''
url_project: ''
url_slides: ''
url_source: ''
url_video: ''
url_preprint: ''

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