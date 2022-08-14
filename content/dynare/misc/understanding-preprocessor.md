---
title: 'Understanding Dynare''s Preprocessor OR How to manually pre-process a DSGE model (with MATLAB)'
linktitle: Understanding Dynare Preprocessor
summary: This is a Zoom recording (hope the quality is still okay) of a session on Dynare's preprocessor and what it actually does. I illustrate preprocessing on a RBC model by manually re-doing some steps in MATLAB with a focus on writing out script files of the static/dynamic model equations and Jacobians. Note that Dynare's preprocessor is written in C++ and is capable to do much more things than I cover in this video, but I still hope this is useful for people who need to manually pre-process a DSGE model.
date: '2022-06-01'
type: book
draft: false
toc: true
weight: 80
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube qTC2hP__WLA >}}

## Description
This is a Zoom recording (hope the quality is still okay) of a session on Dynare's preprocessor and what it actually does. I illustrate preprocessing on a RBC model by manually re-doing some steps in MATLAB with a focus on writing out script files of the static/dynamic model equations and Jacobians.

Note that Dynare's preprocessor is written in C++ and is capable to do much more things than I cover in this video, but I still hope this is useful for people who need to manually preprocess a DSGE model.

## Topics
- Example run of Dynare on RBC model
- What does Dynare's preprocessor create in the "+" folder
- Quick example how MATLAB's symbolic toolbox can help us to pre-process a model
- Preprocessing in MATLAB: define strings for variable and parameter names
- Preprocessing in MATLAB: Enter model equations by defining symbolic variables with different time subscripts
- Preprocessing in MATLAB: create lead_lag_incidence matrix to find dynamic variables
- Preprocessing in MATLAB: distinguish different types of variables depending on their timing
- Preprocessing in MATLAB: compute static model equations
- Preprocessing in MATLAB: compute static Jacobian
- Preprocessing in MATLAB: compute dynamic Jacobian
- Preprocessing in MATLAB: write out symbolic expressions to script files
- Comparison of manually preprocessed script files with the corresponding ones created by Dynare

## References
- Dynare Manual