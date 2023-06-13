---
title: 'Solving DSGE models with first-order perturbation: what Dynare does'
linktitle: first-order perturbation theory
summary: In this video tutorial we have an in-depth look at first-order perturbation techniques.
toc: true
type: book
date: "2023-06-07"
draft: false
weight: 1
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

## Videos
{{< youtube hmVxasBgbqM>}}  {{< youtube hmVxasBgbqM>}}

## Description
This is a video series and a didactic reference and in-depth review of first-order perturbation and how it is implemented in Dynare.

In the first part, we will go through the theory in a general framework also known as the Linear Rational Expectations model and cover the general idea, notation and approach to approximating the policy function of DSGE models at first-order. We will also implement the algorithm in MATLAB and compare it to the solution Dynare computes.
So this part should enable you to understand the theory, intuition and approach of first-order perturbation techniques.

In part II of the series, we will then do an exact illustration of how Dynare computes the first-order perturbation solution by covering numerical tricks such as shrinking the size of the equations by using efficient linear algebra techniques and functions. We will then re-implement Dynare's dyn_first_order_solver.m function in a slightly simplified, but more understandable manner and better notation to exactly replicate the first order solver.

## Slides
- [Presentation Part 1](/files/perturbation/perturbation_order_1_LRE.pdf)
- [Presentation Part 2](/files/perturbation/perturbation_order_1_dynare.pdf)

## Codes
- [nk.mod](/files/perturbation/nk.mod)
- [nk_illustrate_perturbation.mod](/files/perturbation/nk_illustrate_perturbation.mod)
- [nk_var_typology.mod](/files/perturbation/nk_var_typology.mod)
- [perturbation_solver_LRE.m](/files/perturbation/perturbation_solver_LRE.m)
- [perturbation_solver_dynare_order1.m](/files/perturbation/perturbation_solver_dynare_order1.m)

## References
- Julliard (2022) - Introduction to Dynare and local approximation
- Villemot (2011) - Solving rational expectations models at first order: what Dynare does