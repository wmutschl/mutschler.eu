---
title: Introduction to Dynare (very rough and brief) with a focus on solution and simulation methods
date: "2022-04-18"
---
A quick and rough introduction to Dynare on MATLAB with a focus on solution and simulation methods.
<!--more-->

## Video
{{< youtube NDFSUx46FvM >}}

## Topics
- What is Dynare?
- Dynare mod files vs MATLAB script files
- Declaring endogenous and exogenous variables
- Difference between Dynare blocks and MATLAB code
- Declaring parameters and providing numerical values for parameters
- Adding model equations
- Save as mod file, not as m file
- Use addpath to add Dynare to MATLAB
- Running dynare on a mod file
- What Dynare's preprocessor does
- You can have MATLAB code in a mod file
- Compute steady-state numerically
- Steady-state values are not unique, sometimes not all variables can be pinned down
- Compute steady-state in closed-form
- Dynare checks the steady-state
- Stochastic simulations with first order perturbation
- Stochastic simulations with second order perturbation
- Deterministic simulation under perfect foresight
- Adding the zero-lower-bound under perfect foresight
- Extended path simulations
- A typical mod file

## References
- Dynare Manual