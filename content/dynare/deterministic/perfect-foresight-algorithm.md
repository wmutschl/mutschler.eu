---
title: 'The Perfect Foresight Algorithm'
linktitle: Perfect Foresight Algorithm
summary: We cover deterministic simulations in DSGE models also known as perfect foresight simulations and how one can do this in Dynare. Several scenarios are illustrated using a two-country New Keynesian DSGE model with a Zero-Lower-Bound as an example. Dynare specific commands and numerical issues of the Newton algorithm are covered. Finally, we are going to re-implement the Perfect Foresight Algorithm in MATLAB and see that the results are exactly the same.
toc: true
type: book
date: "2023-05-14"
draft: false
weight: 1
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube I6CgzoOfoS0 >}}

## Description
We cover deterministic simulations in DSGE models also known as perfect foresight simulations and how one can do this in Dynare.

1) We will cover very briefly the intuition behind this method.
2) We are going to illustrate several scenarios which you can analyze using a two-country New Keynesian DSGE model as an example.
3) We will go through the Dynare specific commands that you need know.
4) We will go under the hood and derive the Newton type algorithm that Dynare uses and discuss some numerical issues we need to deal with.
5) To make sure that we really understand the algorithm and the way Dynare computes deterministic simulations, we are going to re-implement it manually in MATLAB and then see that the results are exactly the same.

## Slides
- [Presentation](/files/deterministic/Mutschler-2023-Understanding-Deterministic-Simulations.pdf)

## Codes
- [nk2co_common.mod](/files/deterministic/nk2co_common.mod)
- [do_plots.m](/files/deterministic/do_plots.m)
- [nk2co_temp_monpol_surprise.mod](/files/deterministic/nk2co_temp_monpol_surprise.mod)
- [nk2co_temp_monpol_announced.mod](/files/deterministic/nk2co_temp_monpol_announced.mod)
- [nk2co_perm_infltarget_surprise.mod](/files/deterministic/nk2co_perm_infltarget_surprise.mod)
- [nk2co_perm_tax_announced.mod](/files/deterministic/nk2co_perm_tax_announced.mod)
- [nk2co_understand_perfect_foresight.m](/files/deterministic/nk2co_understand_perfect_foresight.m)

## Topics

- Recap Deterministic Simulations under Perfect Foresight
- Example Two-Country NK model with ZLB
  - Temporary Monetary Policy Shock
  - Pre-Announced Temporary Monetary Policy Shock
  - Permanent Increase Inflation Target (Surprise)
  - Pre-Announced Permanent Increase in future tax rates
- Dynare Specifics: Commands and Under the Hood
- General DSGE Framework under Perfect Foresight
- Two-Boundary Value Problem
- Newton Method
- The Perfect Foresight Algorithm
- Controlling Newton Algorithm in Dynare
- Initial Guess for Newton Algorithm
- Infinite Horizon Problems
- Jacobian
- Re-Implementation of Perfect Foresight Algorithm in MATLAB


## References
- Sébastien Villemot (2022) - Deterministic Models, Perfect foresight, nonlinearities and occasionally binding constraints