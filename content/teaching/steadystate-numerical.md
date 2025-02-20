---
title: What does it mean to numerically compute the steady-state in Dynare vs MATLAB
date: "2022-06-01"
---
What is the underlying objective function and what does it mean to use numerical optimization techniques when computing the steady-state? This is illustrated by the RBC model, preprocessed manually in MATLAB and using different optimization methods.
<!--more-->
This is a Zoom recording (hope the quality is still okay) of a session on computing the steady-state of DSGE models numerically. I try to explain what the underlying objective function is and what it means to use numerical optimization techniques. This is illustrated by the RBC model, preprocessed manually in MATLAB and using different optimization methods. I also compare this to what Dynare's steady command does.
Note that Dynare's steady command is capable to do much more things than I cover in this video, but I still hope this is useful for people to understand the underlying objective and approach.

## Video
{{< youtube Hi28OQmkQ80 >}}

## Topics
- Recap how to preprocess DSGE models with MATLAB
- Preprocess RBC model with MATLAB
- (Not so good) explanation of how numerical optimizers (e.g. Newton-Raphson) work
- Vector-valued vs scalar objective functions
- MATLAB: Provide initial values
- MATLAB: Create function handle for vector-valued optimizers
- MATLAB: use fsolve to find steady-state numerically
- MATLAB: use lsqnonlin with bounds to find steady-state numerically
- MATLAB: use fminsearch and sum-of-squared-residuals objective function to find steady-state numerically
- MATLAB: use patternsearch and sum-of-squared-residuals objective function to find steady-state numerically
- Compare residuals and sum-of-squared-residuals
- Compare steady-states computed with MATLAB vs with Dynare vs the analytical way
- Additional info on the steady command in Dynare

## References
- Dynare Manual